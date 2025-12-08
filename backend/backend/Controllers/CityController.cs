using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CityController : BaseCRUDController<City, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        protected new ICityService _service;
        public CityController(ICityService service) : base(service)
        {
            _service = service;
        }

        [HttpDelete("{id}")]
        public override IActionResult Delete(int id)
        {
            _service.DeleteCity(id);
            return NoContent();
        }
    }
}

