using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface ICityService : ICRUDService<City, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        void DeleteCity(int id);
    }
}

