using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class ItemService : BaseCRUDService<Model.Models.Item, ItemSearchObject, Database.Item, ItemInsertRequest, ItemUpdateRequest>, IItemService
    {
        public ItemService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Item> AddFilter(ItemSearchObject search, IQueryable<Database.Item> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.Title.Contains(fts) ||
                    x.Description.Contains(fts) ||
                    (x.Brand != null && x.Brand.Contains(fts)) ||
                    (x.Model != null && x.Model.Contains(fts)));
            }

            if (!string.IsNullOrWhiteSpace(search?.ItemType))
            {
                filteredQuery = filteredQuery.Where(x => x.ItemType == search.ItemType);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (!string.IsNullOrWhiteSpace(search?.Condition))
            {
                filteredQuery = filteredQuery.Where(x => x.Condition == search.Condition);
            }

            if (search != null && search.CompanyId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CompanyId == search.CompanyId.Value);
            }

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (search != null && search.CategoryId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CategoryId == search.CategoryId.Value);
            }

            if (search != null && search.IsAvailable.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsAvailable == search.IsAvailable.Value);
            }

            if (search != null && search.MinPrice.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Price >= search.MinPrice.Value);
            }

            if (search != null && search.MaxPrice.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.Price <= search.MaxPrice.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Brand))
            {
                filteredQuery = filteredQuery.Where(x => x.Brand != null && x.Brand.Contains(search.Brand));
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(ItemInsertRequest request, Database.Item entity)
        {
            if (request.CategoryId.HasValue)
            {
                var categoryExists = Context.Categories.Any(c => c.Id == request.CategoryId.Value);
                if (!categoryExists)
                {
                    throw new UserException("Kategorija nije pronađena.");
                }
            }

            entity.IsAvailable = true;
            entity.TotalPurchases = 0;
            entity.TotalRentals = 0;
            entity.TotalOrders = 0;
            entity.CreatedAt = DateTime.UtcNow;
        }

        public override void BeforeUpdate(ItemUpdateRequest request, Database.Item entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.CategoryId.HasValue)
            {
                var categoryExists = Context.Categories.Any(c => c.Id == request.CategoryId.Value);
                if (!categoryExists)
                {
                    throw new UserException("Kategorija nije pronađena.");
                }
                entity.CategoryId = request.CategoryId.Value;
            }

            if (request.TotalPurchases.HasValue)
            {
                entity.TotalPurchases = request.TotalPurchases.Value;
            }

            if (request.TotalRentals.HasValue)
            {
                entity.TotalRentals = request.TotalRentals.Value;
            }

            if (request.TotalOrders.HasValue)
            {
                entity.TotalOrders = request.TotalOrders.Value;
            }

            if (request.LastSoldDate.HasValue)
            {
                entity.LastSoldDate = request.LastSoldDate.Value;
            }

            if (request.LastRentedDate.HasValue)
            {
                entity.LastRentedDate = request.LastRentedDate.Value;
            }
        }

        public void DeleteItem(int id)
        {
            var item = Context.Items.FirstOrDefault(i => i.Id == id);

            if (item == null)
                throw new UserException("Artikal nije pronađen.");

            Context.Items.Remove(item);
            Context.SaveChanges();
        }
    }
}

