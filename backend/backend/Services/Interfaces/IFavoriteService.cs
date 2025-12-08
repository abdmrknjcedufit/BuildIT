using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IFavoriteService : ICRUDService<Model.Models.Favorite, FavoriteSearchObject, FavoriteInsertRequest, FavoriteUpdateRequest>
    {
        void DeleteFavorite(int id);
    }
}

