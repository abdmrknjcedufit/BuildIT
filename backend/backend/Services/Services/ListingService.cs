using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class ListingService : BaseCRUDService<Model.Models.Listing, ListingSearchObject, Database.Listing, ListingInsertRequest, ListingUpdateRequest>, IListingService
    {
        public ListingService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Listing> AddFilter(ListingSearchObject search, IQueryable<Database.Listing> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.Title.Contains(fts) ||
                    x.Description.Contains(fts));
            }

            if (search != null && search.ItemId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.ItemId == search.ItemId.Value);
            }

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.ListingType))
            {
                filteredQuery = filteredQuery.Where(x => x.ListingType == search.ListingType);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (search != null && search.CityId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CityId == search.CityId.Value);
            }

            if (search != null && search.IsFeatured.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsFeatured == search.IsFeatured.Value);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(ListingInsertRequest request, Database.Listing entity)
        {
            var itemExists = Context.Items.Any(i => i.Id == request.ItemId);
            if (!itemExists)
            {
                throw new UserException("Artikal nije pronađen.");
            }

            var userExists = Context.Users.Any(u => u.Id == request.UserId);
            if (!userExists)
            {
                throw new UserException("Korisnik nije pronađen.");
            }

            if (request.CityId.HasValue)
            {
                var cityExists = Context.Cities.Any(c => c.Id == request.CityId.Value);
                if (!cityExists)
                {
                    throw new UserException("Grad nije pronađen.");
                }
            }

            entity.CreatedAt = DateTime.UtcNow;
        }

        public override void BeforeUpdate(ListingUpdateRequest request, Database.Listing entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.ItemId.HasValue)
            {
                var itemExists = Context.Items.Any(i => i.Id == request.ItemId.Value);
                if (!itemExists)
                {
                    throw new UserException("Artikal nije pronađen.");
                }
                entity.ItemId = request.ItemId.Value;
            }

            if (request.CityId.HasValue)
            {
                var cityExists = Context.Cities.Any(c => c.Id == request.CityId.Value);
                if (!cityExists)
                {
                    throw new UserException("Grad nije pronađen.");
                }
                entity.CityId = request.CityId.Value;
            }

            entity.UpdatedAt = DateTime.UtcNow;
        }

        public void DeleteListing(int id)
        {
            var listing = Context.Listings.FirstOrDefault(l => l.Id == id);

            if (listing == null)
                throw new UserException("Oglas nije pronađen.");

            Context.Listings.Remove(listing);
            Context.SaveChanges();
        }
    }
}

