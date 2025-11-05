using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ListingController : BaseCRUDController<Listing, ListingSearchObject, ListingInsertRequest, ListingUpdateRequest>
    {
        protected new IListingService _service;
        public ListingController(IListingService service) : base(service)
        {
            _service = service;
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            _service.DeleteListing(id);
            return NoContent();
        }
    }
}

