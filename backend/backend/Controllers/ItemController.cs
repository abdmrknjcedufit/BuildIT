using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

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

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<Item> GetList([FromQuery] ItemSearchObject? search = null)
        {
            return base.GetList(search ?? new ItemSearchObject());
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override Item GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpPost]
        [Authorize]
        public override Item Insert([FromBody] ItemInsertRequest request)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (userIdClaim != null && int.TryParse(userIdClaim, out int userId))
            {
                request.UserId = userId;
            }
            return base.Insert(request);
        }

        [HttpDelete("{id}")]
        [Authorize]
        public override IActionResult Delete(int id)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var userRoles = User.Claims
                .Where(c => c.Type == ClaimTypes.Role)
                .Select(c => c.Value)
                .ToList();

            if (userIdClaim == null || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized(new { message = "Korisnički ID nije pronađen." });
            }

            var item = _service.GetById(id);
            if (item == null)
            {
                return NotFound(new { message = "Artikal nije pronađen." });
            }

            if (!userRoles.Contains("Admin") && item.UserId != userId)
            {
                return StatusCode(403, new { message = "Možete obrisati samo svoje artikle." });
            }

            _service.DeleteItem(id);
            return NoContent();
        }
    }
}

