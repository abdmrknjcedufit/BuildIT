using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using AuditLogModel = BuildIT.Model.Models.AuditLog;

namespace BuildIT.Services.Services
{
    public class AuditLogService : BaseService<AuditLogModel, AuditLogSearchObject, Database.AuditLog>, IAuditLogService
    {
        public AuditLogService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.AuditLog> AddFilter(AuditLogSearchObject search, IQueryable<Database.AuditLog> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Username))
            {
                filteredQuery = filteredQuery.Where(x => x.Username != null && x.Username.Contains(search.Username));
            }

            if (!string.IsNullOrWhiteSpace(search?.Action))
            {
                filteredQuery = filteredQuery.Where(x => x.Action.Contains(search.Action));
            }

            if (!string.IsNullOrWhiteSpace(search?.ResponseStatus))
            {
                filteredQuery = filteredQuery.Where(x => x.ResponseStatus == search.ResponseStatus);
            }

            if (search != null && search.FromDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Timestamp >= search.FromDate.Value);
            }

            if (search != null && search.ToDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Timestamp <= search.ToDate.Value);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.Timestamp);

            return filteredQuery;
        }

        public async Task LogAsync(AuditLogInsertRequest request)
        {
            var entity = new Database.AuditLog
            {
                Timestamp = DateTime.UtcNow,
                UserId = request.UserId,
                Username = request.Username,
                Action = request.Action,
                EntityId = request.EntityId,
                RequestData = request.RequestData,
                ResponseStatus = request.ResponseStatus,
                Message = request.Message
            };

            await Context.AuditLogs.AddAsync(entity);
            await Context.SaveChangesAsync();
        }
    }
}
