using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [AllowAnonymous]
    public class ListingController : BaseCRUDController<Model.Models.Listing, ListingSearchObject, ListingInsertRequest, ListingUpdateRequest>
    {
        protected new IListingService _service;
        protected BuildITDbContext _context;
        public ListingController(IListingService service, BuildITDbContext context) : base(service)
        {
            _service = service;
            _context = context;
        }

        [HttpGet]
        [AllowAnonymous]
        public override PagedResult<Model.Models.Listing> GetList([FromQuery] ListingSearchObject searchObject)
        {
            var result = base.GetList(searchObject);
            
            System.Diagnostics.Debug.WriteLine($"🔵 Controller: Returning {result.ResultList.Count} listings, count: {result.Count}");
            if (result.ResultList.Any())
            {
                System.Diagnostics.Debug.WriteLine($"🔵 Controller: First listing ID: {result.ResultList.First().Id}");
                System.Diagnostics.Debug.WriteLine($"🔵 Controller: First listing has Item: {result.ResultList.First().Item != null}");
            }
            
            return result;
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public override Model.Models.Listing GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpDelete("{id}")]
        [Authorize]
        public override IActionResult Delete(int id)
        {
            if (!User.Identity?.IsAuthenticated ?? true)
            {
                return Unauthorized(new { message = "Potrebna je autentifikacija za pristup ovom resursu." });
            }

            var userRoles = User.Claims
                .Where(c => c.Type == System.Security.Claims.ClaimTypes.Role)
                .Select(c => c.Value)
                .ToList();

            var userIdClaim = User.Claims
                .FirstOrDefault(c => c.Type == System.Security.Claims.ClaimTypes.NameIdentifier);

            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out int userId))
            {
                return Unauthorized(new { message = "Korisnički ID nije pronađen." });
            }

            var listing = _context.Listings.FirstOrDefault(l => l.Id == id);
            if (listing == null)
            {
                return NotFound(new { message = "Oglas nije pronađen." });
            }

            if (!userRoles.Contains("Admin") && listing.UserId != userId)
            {
                return StatusCode(403, new { message = "Možete obrisati samo svoje oglase." });
            }

            try
            {
                _service.DeleteListing(id);
                return NoContent();
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/rental-availability")]
        [AllowAnonymous]
        public IActionResult GetRentalAvailability(int id)
        {
            try
            {
                var listing = _context.Listings.FirstOrDefault(l => l.Id == id);
                if (listing == null)
                {
                    return NotFound(new { message = "Oglas nije pronađen." });
                }

                var occupiedDates = new List<object>();

                var orders = _context.Orders
                    .Include(o => o.Transaction)
                    .Where(o => o.Transaction != null && 
                                o.Transaction.ListingId == id &&
                                o.Status != "Cancelled" &&
                                o.PaymentStatus == "Paid")
                    .ToList();

                foreach (var order in orders)
                {
                    if (order.RentalStartDate.HasValue && order.RentalEndDate.HasValue)
                    {
                        var startDate = order.RentalStartDate.Value.Date;
                        var endDate = order.RentalEndDate.Value.Date;
                        
                        var currentDate = startDate;
                        while (currentDate <= endDate)
                        {
                            occupiedDates.Add(new
                            {
                                date = currentDate.ToString("yyyy-MM-dd"),
                                orderId = order.Id,
                                orderNumber = order.OrderNumber
                            });
                            currentDate = currentDate.AddDays(1);
                        }
                    }
                    else if (order.RentalDays.HasValue && order.RentalDays.Value > 0)
                    {
                        var startDate = order.CreatedAt.Date;
                        var endDate = startDate.AddDays(order.RentalDays.Value - 1);
                        
                        var currentDate = startDate;
                        while (currentDate <= endDate)
                        {
                            occupiedDates.Add(new
                            {
                                date = currentDate.ToString("yyyy-MM-dd"),
                                orderId = order.Id,
                                orderNumber = order.OrderNumber
                            });
                            currentDate = currentDate.AddDays(1);
                        }
                    }
                }

                return Ok(new
                {
                    listingId = id,
                    occupiedDates = occupiedDates.DistinctBy(d => ((dynamic)d).date).ToList()
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}

