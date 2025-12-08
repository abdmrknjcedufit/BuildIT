using System;
using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class TransactionService : BaseCRUDService<Model.Models.Transaction, TransactionSearchObject, Database.Transaction, TransactionInsertRequest, TransactionUpdateRequest>, ITransactionService
    {
        public TransactionService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Transaction> AddFilter(TransactionSearchObject search, IQueryable<Database.Transaction> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.ListingId.ToString().Contains(fts) ||
                    (x.StripeTransactionId != null && x.StripeTransactionId.Contains(fts)));
            }

            if (search != null && search.ListingId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.ListingId == search.ListingId.Value);
            }

            if (search != null && search.BuyerId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.BuyerId == search.BuyerId.Value);
            }

            if (search != null && search.SellerId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.SellerId == search.SellerId.Value);
            }

            if (search != null && search.FromDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.TransactionDate.Date >= search.FromDate.Value.Date);
            }

            if (search != null && search.ToDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.TransactionDate.Date <= search.ToDate.Value.Date);
            }

            if (search != null && search.MinAmount.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Amount >= search.MinAmount.Value);
            }

            if (search != null && search.MaxAmount.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Amount <= search.MaxAmount.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (!string.IsNullOrWhiteSpace(search?.Type))
            {
                filteredQuery = filteredQuery.Where(x => x.Type == search.Type);
            }

            if (!string.IsNullOrWhiteSpace(search?.PaymentMethod))
            {
                filteredQuery = filteredQuery.Where(x => x.PaymentMethod == search.PaymentMethod);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.TransactionDate);

            return filteredQuery;
        }

        public override PagedResult<Model.Models.Transaction> GetPaged(TransactionSearchObject search)
        {
            var query = Context.Transactions
                .Include(x => x.Listing)
                    .ThenInclude(l => l.Item)
                .Include(x => x.Buyer)
                .Include(x => x.Seller)
                .AsQueryable();

            query = AddFilter(search, query);

            int count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                int page = search.Page.Value > 0 ? search.Page.Value - 1 : 0;
                int pageSize = search.PageSize.Value > 0 ? search.PageSize.Value : 10;
                query = query.Skip(page * pageSize).Take(pageSize);
            }

            var list = query.ToList();
            List<Model.Models.Transaction> result = new List<Model.Models.Transaction>();

            try
            {
                result = Mapper.Map<List<Model.Models.Transaction>>(list);
            }
            catch (Exception ex)
            {
                throw new UserException($"Greška pri mapiranju podataka: {ex.Message}");
            }

            PagedResult<Model.Models.Transaction> pagedResult = new PagedResult<Model.Models.Transaction>();
            pagedResult.ResultList = result;
            pagedResult.Count = count;

            return pagedResult;
        }

        public override void BeforeInsert(TransactionInsertRequest request, Database.Transaction entity)
        {
            var listingExists = Context.Listings.Any(l => l.Id == request.ListingId);
            if (!listingExists)
            {
                throw new UserException("Oglas nije pronađen.");
            }

            var buyerExists = Context.Users.Any(u => u.Id == request.BuyerId);
            if (!buyerExists)
            {
                throw new UserException("Kupac nije pronađen.");
            }

            var sellerExists = Context.Users.Any(u => u.Id == request.SellerId);
            if (!sellerExists)
            {
                throw new UserException("Prodavac nije pronađen.");
            }

            entity.CreatedAt = DateTime.UtcNow;
        }

        public override void BeforeUpdate(TransactionUpdateRequest request, Database.Transaction entity)
        {
            base.BeforeUpdate(request, entity);
        }
    }
}

