using BuildIT.Model;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;

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
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);
            }

            var list = query.ToList();

            result = Mapper.Map(list, result);

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

