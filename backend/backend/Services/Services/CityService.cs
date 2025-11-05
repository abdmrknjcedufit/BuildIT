using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class CityService : BaseCRUDService<Model.Models.City, CitySearchObject, Database.City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        public CityService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.City> AddFilter(CitySearchObject search, IQueryable<Database.City> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x => x.Name.Contains(fts));
            }

            if (search != null && search.IsActive.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsActive == search.IsActive.Value);
            }

            filteredQuery = filteredQuery.OrderBy(x => x.Name);

            return filteredQuery;
        }

        public void DeleteCity(int id)
        {
            var city = Context.Cities.FirstOrDefault(c => c.Id == id);

            if (city == null)
                throw new UserException("Grad nije pronađen.");

            Context.Cities.Remove(city);
            Context.SaveChanges();
        }
    }
}

