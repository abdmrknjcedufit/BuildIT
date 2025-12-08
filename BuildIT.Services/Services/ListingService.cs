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

        public override PagedResult<Model.Models.Listing> GetPaged(ListingSearchObject search)
        {
            var query = Context.Listings
                .Include(x => x.Item)
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
            
            System.Diagnostics.Debug.WriteLine($"🔵 Loaded {list.Count} listings from database");
            if (list.Any())
            {
                System.Diagnostics.Debug.WriteLine($"🔵 First listing ID: {list.First().Id}, ItemId: {list.First().ItemId}");
                System.Diagnostics.Debug.WriteLine($"🔵 First listing has Item: {list.First().Item != null}");
                if (list.First().Item != null)
                {
                    System.Diagnostics.Debug.WriteLine($"🔵 First listing Item Title: {list.First().Item.Title}");
                }
            }

            List<Model.Models.Listing> result = new List<Model.Models.Listing>();
            
            try
            {
                foreach (var listing in list)
                {
                    var mappedListing = new Model.Models.Listing
                    {
                        Id = listing.Id,
                        ItemId = listing.ItemId,
                        UserId = listing.UserId,
                        Title = listing.Title,
                        Description = listing.Description,
                        ListingType = listing.ListingType,
                        Status = listing.Status,
                        CityId = listing.CityId,
                        IsFeatured = listing.IsFeatured,
                        CreatedAt = listing.CreatedAt,
                        UpdatedAt = listing.UpdatedAt,
                        Images = listing.Images,
                        MinRentalDays = listing.MinRentalDays,
                        MaxRentalDays = listing.MaxRentalDays,
                        Item = listing.Item != null ? Mapper.Map<Model.Models.Item>(listing.Item) : null
                    };
                    result.Add(mappedListing);
                }
                
                System.Diagnostics.Debug.WriteLine($"✅ Mapped {result.Count} listings");
                if (result.Any())
                {
                    System.Diagnostics.Debug.WriteLine($"✅ First mapped listing ID: {result.First().Id}");
                    System.Diagnostics.Debug.WriteLine($"✅ First mapped listing has Item: {result.First().Item != null}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"❌ Mapping error: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"❌ Stack trace: {ex.StackTrace}");
                throw new UserException($"Greška pri mapiranju listinga: {ex.Message}");
            }

            PagedResult<Model.Models.Listing> pagedResult = new PagedResult<Model.Models.Listing>();
            pagedResult.ResultList = result;
            pagedResult.Count = count;

            System.Diagnostics.Debug.WriteLine($"🔵 Returning {pagedResult.ResultList.Count} listings, count: {pagedResult.Count}");

            return pagedResult;
        }

        public override void BeforeInsert(ListingInsertRequest request, Database.Listing entity)
        {
            var item = Context.Items.FirstOrDefault(i => i.Id == request.ItemId);
            if (item == null)
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

            entity.Images = null;

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

            if (request.MinRentalDays.HasValue)
            {
                entity.MinRentalDays = request.MinRentalDays.Value;
            }

            if (request.MaxRentalDays.HasValue)
            {
                entity.MaxRentalDays = request.MaxRentalDays.Value;
            }

            if (request.IsFeatured.HasValue)
            {
                entity.IsFeatured = request.IsFeatured.Value;
            }

            if (!string.IsNullOrWhiteSpace(request.Title))
            {
                entity.Title = request.Title;
            }

            if (!string.IsNullOrWhiteSpace(request.Description))
            {
                entity.Description = request.Description;
            }

            if (!string.IsNullOrWhiteSpace(request.ListingType))
            {
                entity.ListingType = request.ListingType;
            }

            if (!string.IsNullOrWhiteSpace(request.Status))
            {
                entity.Status = request.Status;
            }

            entity.Images = null;

            entity.UpdatedAt = DateTime.UtcNow;
        }

        public override Model.Models.Listing GetById(int id)
        {
            var entity = Context.Listings
                .Include(x => x.Item)
                .Include(x => x.User)
                .Include(x => x.City)
                .FirstOrDefault(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Oglas nije pronađen");
            }

            var mappedListing = new Model.Models.Listing
            {
                Id = entity.Id,
                ItemId = entity.ItemId,
                UserId = entity.UserId,
                Title = entity.Title,
                Description = entity.Description,
                ListingType = entity.ListingType,
                Status = entity.Status,
                CityId = entity.CityId,
                IsFeatured = entity.IsFeatured,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
                Images = entity.Images,
                MinRentalDays = entity.MinRentalDays,
                MaxRentalDays = entity.MaxRentalDays,
                Item = entity.Item != null ? Mapper.Map<Model.Models.Item>(entity.Item) : null,
                User = entity.User != null ? Mapper.Map<Model.Models.User>(entity.User) : null,
                City = entity.City != null ? Mapper.Map<Model.Models.City>(entity.City) : null
            };

            return mappedListing;
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

