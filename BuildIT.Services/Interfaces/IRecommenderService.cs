using BuildIT.Model.Models;
using ListingModel = BuildIT.Model.Models.Listing;

namespace BuildIT.Services.Interfaces
{
    public interface IRecommenderService
    {
        List<ListingModel> GetRecommendations(int userId, int count = 10);
    }
}

