using BuildIT.Model;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IService<TModel, TSearch> where TSearch : BaseSearchObject
    {
        public PagedResult<TModel> GetPaged(TSearch search);
        public TModel GetById(int id);
    }
}

