using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services;

public class CartService : BaseCRUDService<Model.Models.Cart, CartSearchObject, Database.Cart, CartInsertRequest, CartUpdateRequest>, ICartService
{
    public CartService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
    {
    }

    public override IQueryable<Database.Cart> AddFilter(CartSearchObject search, IQueryable<Database.Cart> query)
    {
        var filteredQuery = base.AddFilter(search, query);
        
        if (search != null && search.UserId.HasValue)
        {
            filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
        }
        
        return filteredQuery;
    }

    public override PagedResult<Model.Models.Cart> GetPaged(CartSearchObject search)
    {
        var query = Context.Carts
            .Include(x => x.Listing)
            .ThenInclude(l => l.Item)
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
        var resultList = new List<Model.Models.Cart>();

        foreach (var cart in list)
        {
            var mappedCart = Mapper.Map<Model.Models.Cart>(cart);
            if (cart.Listing != null)
            {
                mappedCart.Listing = new Model.Models.Listing
                {
                    Id = cart.Listing.Id,
                    ItemId = cart.Listing.ItemId,
                    UserId = cart.Listing.UserId,
                    Title = cart.Listing.Title,
                    Description = cart.Listing.Description,
                    ListingType = cart.Listing.ListingType,
                    Status = cart.Listing.Status,
                    CityId = cart.Listing.CityId,
                    IsFeatured = cart.Listing.IsFeatured,
                    CreatedAt = cart.Listing.CreatedAt,
                    UpdatedAt = cart.Listing.UpdatedAt,
                    MinRentalDays = cart.Listing.MinRentalDays,
                    MaxRentalDays = cart.Listing.MaxRentalDays,
                    Item = cart.Listing.Item != null ? Mapper.Map<Model.Models.Item>(cart.Listing.Item) : null
                };
            }
            resultList.Add(mappedCart);
        }

        var result = new PagedResult<Model.Models.Cart>
        {
            Count = count,
            ResultList = resultList
        };

        return result;
    }

    public override Model.Models.Cart Insert(CartInsertRequest request)
    {
        var listing = Context.Listings
            .Include(l => l.Item)
            .FirstOrDefault(l => l.Id == request.ListingId);

        if (listing == null)
        {
            throw new Exception("Oglas nije pronađen");
        }

        var existingCart = Context.Carts
            .FirstOrDefault(c => c.UserId == request.UserId && c.ListingId == request.ListingId);

        if (existingCart != null)
        {
            existingCart.Quantity += request.Quantity;
            if (request.RentalDays.HasValue)
            {
                existingCart.RentalDays = request.RentalDays.Value;
                existingCart.PricePerDay = listing.Item?.Price ?? 0;
            }
            existingCart.TotalPrice = CalculateTotalPrice(existingCart.Quantity, existingCart.RentalDays, existingCart.PricePerDay);
            existingCart.UpdatedAt = DateTime.Now;
            Context.Carts.Update(existingCart);
            Context.SaveChanges();

            var updated = Context.Carts
                .Include(c => c.Listing)
                .ThenInclude(l => l.Item)
                .FirstOrDefault(c => c.Id == existingCart.Id);

            if (updated == null)
            {
                throw new Exception("Greška pri ažuriranju korpe");
            }

            var updatedMappedCart = Mapper.Map<Model.Models.Cart>(updated);
            if (updated.Listing != null)
            {
                updatedMappedCart.Listing = new Model.Models.Listing
                {
                    Id = updated.Listing.Id,
                    ItemId = updated.Listing.ItemId,
                    UserId = updated.Listing.UserId,
                    Title = updated.Listing.Title,
                    Description = updated.Listing.Description,
                    ListingType = updated.Listing.ListingType,
                    Status = updated.Listing.Status,
                    CityId = updated.Listing.CityId,
                    IsFeatured = updated.Listing.IsFeatured,
                    CreatedAt = updated.Listing.CreatedAt,
                    UpdatedAt = updated.Listing.UpdatedAt,
                    MinRentalDays = updated.Listing.MinRentalDays,
                    MaxRentalDays = updated.Listing.MaxRentalDays,
                    Item = updated.Listing.Item != null ? Mapper.Map<Model.Models.Item>(updated.Listing.Item) : null
                };
            }
            return updatedMappedCart;
        }

        var entity = new Database.Cart
        {
            UserId = request.UserId,
            ListingId = request.ListingId,
            Quantity = request.Quantity,
            RentalDays = request.RentalDays,
            PricePerDay = listing.Item?.Price,
            TotalPrice = CalculateTotalPrice(request.Quantity, request.RentalDays, listing.Item?.Price),
            CreatedAt = DateTime.Now
        };

        Context.Carts.Add(entity);
        Context.SaveChanges();

        var inserted = Context.Carts
            .Include(c => c.Listing)
            .ThenInclude(l => l.Item)
            .FirstOrDefault(c => c.Id == entity.Id);

        if (inserted == null)
        {
            throw new Exception("Greška pri kreiranju korpe");
        }

        var insertedMappedCart = Mapper.Map<Model.Models.Cart>(inserted);
        if (inserted.Listing != null)
        {
            insertedMappedCart.Listing = new Model.Models.Listing
            {
                Id = inserted.Listing.Id,
                ItemId = inserted.Listing.ItemId,
                UserId = inserted.Listing.UserId,
                Title = inserted.Listing.Title,
                Description = inserted.Listing.Description,
                ListingType = inserted.Listing.ListingType,
                Status = inserted.Listing.Status,
                CityId = inserted.Listing.CityId,
                IsFeatured = inserted.Listing.IsFeatured,
                CreatedAt = inserted.Listing.CreatedAt,
                UpdatedAt = inserted.Listing.UpdatedAt,
                MinRentalDays = inserted.Listing.MinRentalDays,
                MaxRentalDays = inserted.Listing.MaxRentalDays,
                Item = inserted.Listing.Item != null ? Mapper.Map<Model.Models.Item>(inserted.Listing.Item) : null
            };
        }
        return insertedMappedCart;
    }

    public override Model.Models.Cart Update(int id, CartUpdateRequest request)
    {
        var entity = Context.Carts
            .Include(c => c.Listing)
            .ThenInclude(l => l.Item)
            .FirstOrDefault(c => c.Id == id);

        if (entity == null)
        {
            throw new Exception("Stavka korpe nije pronađena");
        }

        entity.Quantity = request.Quantity;
        if (request.RentalDays.HasValue)
        {
            entity.RentalDays = request.RentalDays.Value;
        }
        entity.TotalPrice = CalculateTotalPrice(entity.Quantity, entity.RentalDays, entity.PricePerDay);
        entity.UpdatedAt = DateTime.Now;

        Context.Carts.Update(entity);
        Context.SaveChanges();

        var updated = Context.Carts
            .Include(c => c.Listing)
            .ThenInclude(l => l.Item)
            .FirstOrDefault(c => c.Id == entity.Id);

        if (updated == null)
        {
            throw new Exception("Greška pri ažuriranju korpe");
        }

        var updateMappedCart = Mapper.Map<Model.Models.Cart>(updated);
        if (updated.Listing != null)
        {
            updateMappedCart.Listing = new Model.Models.Listing
            {
                Id = updated.Listing.Id,
                ItemId = updated.Listing.ItemId,
                UserId = updated.Listing.UserId,
                Title = updated.Listing.Title,
                Description = updated.Listing.Description,
                ListingType = updated.Listing.ListingType,
                Status = updated.Listing.Status,
                CityId = updated.Listing.CityId,
                IsFeatured = updated.Listing.IsFeatured,
                CreatedAt = updated.Listing.CreatedAt,
                UpdatedAt = updated.Listing.UpdatedAt,
                MinRentalDays = updated.Listing.MinRentalDays,
                MaxRentalDays = updated.Listing.MaxRentalDays,
                Item = updated.Listing.Item != null ? Mapper.Map<Model.Models.Item>(updated.Listing.Item) : null
            };
        }
        return updateMappedCart;
    }

    public void DeleteCartItem(int id)
    {
        var cartItem = Context.Carts.FirstOrDefault(c => c.Id == id);

        if (cartItem == null)
            throw new Exception("Stavka korpe nije pronađena.");

        Context.Carts.Remove(cartItem);
        Context.SaveChanges();
    }

    private decimal CalculateTotalPrice(int quantity, int? rentalDays, decimal? pricePerDay)
    {
        if (rentalDays.HasValue && pricePerDay.HasValue)
        {
            return quantity * rentalDays.Value * pricePerDay.Value;
        }
        return quantity * (pricePerDay ?? 0);
    }
}

