using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class ComplaintService : BaseCRUDService<Model.Models.Complaint, ComplaintSearchObject, Database.Complaint, ComplaintInsertRequest, ComplaintUpdateRequest>, IComplaintService
    {
        public ComplaintService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Complaint> AddFilter(ComplaintSearchObject search, IQueryable<Database.Complaint> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (!string.IsNullOrWhiteSpace(search?.Priority))
            {
                filteredQuery = filteredQuery.Where(x => x.Priority == search.Priority);
            }

            if (!string.IsNullOrWhiteSpace(search?.TargetType))
            {
                filteredQuery = filteredQuery.Where(x => x.TargetType == search.TargetType);
            }

            if (search != null && search.FromDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CreatedAt.Date >= search.FromDate.Value.Date);
            }

            if (search != null && search.ToDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CreatedAt.Date <= search.ToDate.Value.Date);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(ComplaintInsertRequest request, Database.Complaint entity)
        {
            var userExists = Context.Users.Any(u => u.Id == request.UserId);
            if (!userExists)
            {
                throw new UserException("Korisnik nije pronađen.");
            }

            if (string.IsNullOrWhiteSpace(request.TargetType))
            {
                throw new UserException("TargetType je obavezan.");
            }

            if (string.IsNullOrWhiteSpace(request.Subject))
            {
                throw new UserException("Naslov žalbe je obavezan.");
            }

            if (string.IsNullOrWhiteSpace(request.Description))
            {
                throw new UserException("Opis žalbe je obavezan.");
            }

            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = null;

            if (request.ResolvedAt.HasValue)
            {
                entity.ResolvedAt = request.ResolvedAt.Value;
                entity.Status = "Resolved";
                entity.UpdatedAt = DateTime.UtcNow;
            }
        }

        public override void BeforeUpdate(ComplaintUpdateRequest request, Database.Complaint entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.Subject != null)
            {
                entity.Subject = request.Subject;
            }

            if (request.Description != null)
            {
                entity.Description = request.Description;
            }

            if (request.Status != null)
            {
                entity.Status = request.Status;
            }

            if (request.Priority != null)
            {
                entity.Priority = request.Priority;
            }

            if (request.Attachment != null)
            {
                entity.Attachment = request.Attachment;
            }

            if (request.ResolvedAt.HasValue)
            {
                entity.ResolvedAt = request.ResolvedAt.Value;
            }

            entity.UpdatedAt = DateTime.UtcNow;
        }
    }
}

