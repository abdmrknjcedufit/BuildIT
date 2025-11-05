using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ItemController : BaseCRUDController<Item, ItemSearchObject, ItemInsertRequest, ItemUpdateRequest>
    {
        protected new IItemService _service;
        public ItemController(IItemService service) : base(service)
        {
            _service = service;
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            _service.DeleteItem(id);
            return NoContent();
        }
    }
}

