using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReviewController : BaseCRUDController<Review, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        protected new IReviewService _service;
        public ReviewController(IReviewService service) : base(service)
        {
            _service = service;
        }
    }
}
