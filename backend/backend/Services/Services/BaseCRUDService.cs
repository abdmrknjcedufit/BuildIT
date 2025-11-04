using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;

namespace BuildIT.Services.Services
{
    public abstract class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate> : BaseService<TModel, TSearch, TDbEntity> where TModel : class where TSearch : BaseSearchObject where TDbEntity : class
    {
        public BaseCRUDService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public virtual TModel Insert(TInsert request)
        {
            if (request == null)
                throw new ArgumentNullException(nameof(request));

            TDbEntity entity = Mapper.Map<TDbEntity>(request);

            BeforeInsert(request, entity);

            Context.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<TModel>(entity);
        }

        public virtual void BeforeInsert(TInsert request, TDbEntity entity) { }

        public virtual TModel Update(int id, TUpdate request)
        {
            if (request == null)
                throw new ArgumentNullException(nameof(request));

            var set = Context.Set<TDbEntity>();

            var entity = set.Find(id);
            
            if (entity == null)
            {
                throw new BuildIT.Model.UserException("Entitet nije pronađen");
            }

            BeforeUpdate(request, entity);

            Mapper.Map(request, entity);

            Context.SaveChanges();

            return Mapper.Map<TModel>(entity);
        }

        public virtual void BeforeUpdate(TUpdate request, TDbEntity entity) { }
    }
}

