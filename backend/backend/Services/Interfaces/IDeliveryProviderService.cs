using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces;

public interface IDeliveryProviderService : ICRUDService<DeliveryProvider, DeliveryProviderSearchObject, DeliveryProviderInsertRequest, DeliveryProviderUpdateRequest>
{
}

