using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class ReviewService : BaseCRUDService<Model.Models.Review, ReviewSearchObject, Database.Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        public ReviewService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Review> AddFilter(ReviewSearchObject search, IQueryable<Database.Review> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.Comment != null && x.Comment.Contains(fts));
            }

            if (search != null && search.ReviewerId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.ReviewerId == search.ReviewerId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.TargetType))
            {
                filteredQuery = filteredQuery.Where(x => x.TargetType == search.TargetType);
            }

            if (search != null && search.TargetId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.TargetId == search.TargetId.Value);
            }

            if (search != null && search.TransactionId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.TransactionId == search.TransactionId.Value);
            }

            if (search != null && search.MinRating.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Rating >= search.MinRating.Value);
            }

            if (search != null && search.MaxRating.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Rating <= search.MaxRating.Value);
            }

            if (search != null && search.IsApproved.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsApproved == search.IsApproved.Value);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(ReviewInsertRequest request, Database.Review entity)
        {
            ValidateTarget(request.TargetType, request.TargetId);

            var reviewerExists = Context.Users.Any(u => u.Id == request.ReviewerId);
            if (!reviewerExists)
            {
                throw new UserException("Korisnik (recenzent) nije pronađen.");
            }

            if (request.TransactionId.HasValue)
            {
                var transactionExists = Context.Transactions.Any(t => t.Id == request.TransactionId.Value);
                if (!transactionExists)
                {
                    throw new UserException("Transakcija nije pronađena.");
                }

                var existingReview = Context.Reviews
                    .FirstOrDefault(r => r.TransactionId == request.TransactionId.Value && 
                                        r.ReviewerId == request.ReviewerId);
                if (existingReview != null)
                {
                    throw new UserException("Već ste ostavili ocjenu za ovu narudžbu.");
                }
            }

            if (request.Rating < 1 || request.Rating > 5)
            {
                throw new UserException("Ocjena mora biti između 1 i 5.");
            }

            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = null;
        }

        public override void BeforeUpdate(ReviewUpdateRequest request, Database.Review entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.Rating.HasValue)
            {
                if (request.Rating.Value < 1 || request.Rating.Value > 5)
                {
                    throw new UserException("Ocjena mora biti između 1 i 5.");
                }
                entity.Rating = request.Rating.Value;
            }

            if (request.Comment != null)
            {
                entity.Comment = request.Comment;
            }

            if (request.IsApproved.HasValue)
            {
                entity.IsApproved = request.IsApproved.Value;
            }

            if (request.HelpfulCount.HasValue)
            {
                entity.HelpfulCount = request.HelpfulCount.Value;
            }

            if (request.NotHelpfulCount.HasValue)
            {
                entity.NotHelpfulCount = request.NotHelpfulCount.Value;
            }

            entity.UpdatedAt = DateTime.UtcNow;
        }

        private void ValidateTarget(string targetType, int targetId)
        {
            if (string.IsNullOrWhiteSpace(targetType))
            {
                throw new UserException("TargetType je obavezan.");
            }

            var normalizedType = targetType.Trim();

            if (normalizedType == "Item")
            {
                var listingExists = Context.Listings.Any(l => l.Id == targetId);
                if (!listingExists)
                {
                    throw new UserException("Oglas nije pronađen.");
                }
            }
            else if (normalizedType == "Company")
            {
                var exists = Context.Companies.Any(c => c.Id == targetId);
                if (!exists)
                {
                    throw new UserException("Kompanija nije pronađena.");
                }
            }
            else
            {
                throw new UserException("Podržane vrijednosti za TargetType su 'Item' ili 'Company'.");
            }
        }
    }
}
