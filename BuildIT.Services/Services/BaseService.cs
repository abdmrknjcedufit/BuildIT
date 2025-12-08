using BuildIT.Model;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public abstract class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch> where TSearch : BaseSearchObject where TDbEntity : class where TModel : class
    {
        protected BuildITDbContext Context { get; }
        protected IMapper Mapper { get; }
        public BaseService(BuildITDbContext context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }

        public virtual PagedResult<TModel> GetPaged(TSearch search)
        {
            List<TModel> result = new List<TModel>();

            var query = Context.Set<TDbEntity>().AsQueryable();

            query = AddFilter(search, query);

            int count = query.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                int page = search.Page.Value > 0 ? search.Page.Value - 1 : 0;
                int pageSize = search.PageSize.Value > 0 ? search.PageSize.Value : 10;
                query = query.Skip(page * pageSize).Take(pageSize);
            }

            var list = query.ToList();

            try
            {
                result = Mapper.Map<List<TModel>>(list);
            }
            catch (Exception ex)
            {
                throw new UserException($"Greška pri mapiranju podataka: {ex.Message}");
            }

            PagedResult<TModel> pagedResult = new PagedResult<TModel>();
            pagedResult.ResultList = result;
            pagedResult.Count = count;

            return pagedResult;
        }

        public virtual IQueryable<TDbEntity> AddFilter(TSearch search, IQueryable<TDbEntity> query)
        {
            return query;
        }

        public virtual TModel GetById(int id)
        {
            var entity = Context.Set<TDbEntity>().Find(id);

            if (entity == null)
            {
                throw new UserException("Entitet nije pronađen");
            }

            return Mapper.Map<TModel>(entity);
        }
    }
}

