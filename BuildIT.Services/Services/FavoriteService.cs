using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Mapster;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class FavoriteService : BaseCRUDService<Model.Models.Favorite, FavoriteSearchObject, Database.Favorite, FavoriteInsertRequest, FavoriteUpdateRequest>, IFavoriteService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public FavoriteService(BuildITDbContext context, MapsterMapper.IMapper mapper, IHttpContextAccessor httpContextAccessor) : base(context, mapper)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public override Model.Models.Favorite Insert(FavoriteInsertRequest request)
        {
            var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                throw new Exception("Korisnik nije prijavljen.");
            }

            var existingFavorite = Context.Favorites
                .FirstOrDefault(f => f.UserId == userId && f.ListingId == request.ListingId);

            if (existingFavorite != null)
            {
                throw new Exception("Oglas je već sačuvan u omiljenim.");
            }

            var entity = new Database.Favorite
            {
                UserId = userId,
                ListingId = request.ListingId,
                CreatedAt = DateTime.UtcNow
            };

            Context.Favorites.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<Model.Models.Favorite>(entity);
        }

        public override PagedResult<Model.Models.Favorite> GetPaged(FavoriteSearchObject? search = null)
        {
            search ??= new FavoriteSearchObject();

            var query = Context.Favorites.AsQueryable();

            if (search.UserId.HasValue)
            {
                query = query.Where(f => f.UserId == search.UserId.Value);
            }

            if (search.ListingId.HasValue)
            {
                query = query.Where(f => f.ListingId == search.ListingId.Value);
            }

            var totalCount = query.Count();

            query = query
                .Include(f => f.Listing)
                .ThenInclude(l => l.Item)
                .OrderByDescending(f => f.CreatedAt);

            if (search.Page.HasValue && search.PageSize.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value)
                             .Take(search.PageSize.Value);
            }

            var list = query.ToList();
            var mappedList = list.Select(Mapper.Map<Model.Models.Favorite>).ToList();

            var result = new PagedResult<Model.Models.Favorite>();
            result.ResultList = mappedList;
            result.Count = totalCount;
            return result;
        }

        public void DeleteFavorite(int id)
        {
            var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                throw new Exception("Korisnik nije prijavljen.");
            }

            var entity = Context.Favorites
                .FirstOrDefault(f => f.Id == id && f.UserId == userId);

            if (entity == null)
            {
                throw new Exception("Omiljeni oglas nije pronađen.");
            }

            Context.Favorites.Remove(entity);
            Context.SaveChanges();
        }
    }
}

