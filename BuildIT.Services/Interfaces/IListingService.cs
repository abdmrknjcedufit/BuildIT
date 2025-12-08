using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IListingService : ICRUDService<Listing, ListingSearchObject, ListingInsertRequest, ListingUpdateRequest>
    {
        void DeleteListing(int id);
    }
}

