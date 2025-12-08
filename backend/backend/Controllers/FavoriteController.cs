using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class FavoriteController : BaseCRUDController<BuildIT.Model.Models.Favorite, FavoriteSearchObject, FavoriteInsertRequest, FavoriteUpdateRequest>
    {
        protected new IFavoriteService _service;
        private readonly BuildITDbContext _context;

        public FavoriteController(IFavoriteService service, BuildITDbContext context) : base(service)
        {
            _service = service;
            _context = context;
        }

        [HttpDelete("listing/{listingId}")]
        public IActionResult DeleteByListingId(int listingId)
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                {
                    return Unauthorized(new { message = "Korisnik nije prijavljen." });
                }

                var favorite = _context.Favorites
                    .FirstOrDefault(f => f.UserId == userId && f.ListingId == listingId);

                if (favorite == null)
                {
                    return NotFound(new { message = "Omiljeni oglas nije pronađen." });
                }

                _service.DeleteFavorite(favorite.Id);
                return Ok(new { message = "Oglas je uklonjen iz omiljenih." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public override IActionResult Delete(int id)
        {
            try
            {
                _service.DeleteFavorite(id);
                return Ok(new { message = "Oglas je uklonjen iz omiljenih." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}

