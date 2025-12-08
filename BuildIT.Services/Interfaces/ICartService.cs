using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces;

public interface ICartService : ICRUDService<Cart, CartSearchObject, CartInsertRequest, CartUpdateRequest>
{
    void DeleteCartItem(int id);
}

