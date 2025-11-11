using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IReviewService : ICRUDService<Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
    }
}
