using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class NotificationService : BaseCRUDService<Model.Models.Notification, NotificationSearchObject, Database.Notification, NotificationInsertRequest, NotificationUpdateRequest>, INotificationService
    {
        public NotificationService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Notification> AddFilter(NotificationSearchObject search, IQueryable<Database.Notification> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.NotificationType))
            {
                filteredQuery = filteredQuery.Where(x => x.NotificationType == search.NotificationType);
            }

            if (search != null && search.IsRead.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsRead == search.IsRead.Value);
            }

            if (search != null && search.IsSent.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsSent == search.IsSent.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Priority))
            {
                filteredQuery = filteredQuery.Where(x => x.Priority == search.Priority);
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

        public override void BeforeInsert(NotificationInsertRequest request, Database.Notification entity)
        {
            var userExists = Context.Users.Any(u => u.Id == request.UserId);
            if (!userExists)
            {
                throw new UserException("Korisnik nije pronađen.");
            }

            if (string.IsNullOrWhiteSpace(request.Title))
            {
                throw new UserException("Naslov je obavezan.");
            }

            if (string.IsNullOrWhiteSpace(request.Message))
            {
                throw new UserException("Poruka je obavezna.");
            }

            if (string.IsNullOrWhiteSpace(request.NotificationType))
            {
                throw new UserException("Tip notifikacije je obavezan.");
            }

            entity.CreatedAt = DateTime.UtcNow;

            if (request.IsSent && !request.SentAt.HasValue)
            {
                entity.SentAt = DateTime.UtcNow;
            }
        }

        public override void BeforeUpdate(NotificationUpdateRequest request, Database.Notification entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.IsSent.HasValue && request.IsSent.Value && !entity.SentAt.HasValue)
            {
                entity.SentAt = DateTime.UtcNow;
            }
        }
    }
}
