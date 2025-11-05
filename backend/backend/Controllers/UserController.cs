using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UserController : BaseCRUDController<User, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        protected new IUserService _service;
        public UserController(IUserService service) : base(service)
        {
            _service = service;
        }

        [AllowAnonymous]
        public override User Insert(UserInsertRequest request)
        {
            return base.Insert(request);
        }

        [HttpGet("user-types")]
        [AllowAnonymous]
        public IActionResult GetUserTypes()
        {
            var userTypes = new[]
            {
                new { value = "Individual", label = "Kupac/Fizičko lice" },
                new { value = "Company", label = "Firma/Pravno lice" }
            };

            return Ok(userTypes);
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public IActionResult Login([FromBody] LoginRequest request)
        {
            var user = _service.Login(request.username, request.password);

            var clientTypeRaw = Request.Headers["X-Client-Type"].ToString();
            var clientType = !string.IsNullOrEmpty(clientTypeRaw) ? clientTypeRaw.Trim().ToLower() : null;

            if (string.IsNullOrEmpty(clientType))
            {
                if (user.Roles.Contains("Admin"))
                {
                    return Ok(new { user, clientType = "desktop", message = "Admin korisnik se prijavio. Samo desktop pristup." });
                }
                else
                {
                    return Ok(new { user, clientType = "mobile", message = "Korisnik se prijavio. Samo mobilni pristup." });
                }
            }

            if (clientType != "desktop" && clientType != "mobile")
            {
                return BadRequest(new { message = "Nevažeći 'X-Client-Type' header. Mora biti 'desktop' ili 'mobile'." });
            }

            if (clientType == "desktop" && !user.Roles.Contains("Admin"))
            {
                return Unauthorized(new { message = "Samo administratori mogu se prijaviti iz desktop aplikacije." });
            }

            if (clientType == "mobile" && user.Roles.Contains("Admin"))
            {
                return Unauthorized(new { message = "Administratori se ne mogu prijaviti iz mobilne aplikacije." });
            }

            return Ok(user);
        }

        [Authorize(Roles = "Admin")]
        [HttpPatch("{id}/status")]
        public IActionResult ToggleUserStatus(int id, [FromBody] UserToggleActiveRequest request)
        {
            var user = _service.ToggleActiveStatus(id, request);
            return Ok(user);
        }

        [Authorize(Roles = "Admin")]
        [HttpPost("{id}/reset-password")]
        public IActionResult ResetPassword(int id, [FromBody] ResetPasswordRequest request)
        {
            try
            {
                var result = _service.ResetPassword(id, request.NewPassword);
                return Ok(new { 
                    username = result.Username, 
                    password = result.Password,
                    message = "Lozinka je uspješno resetovana. Sada se možete prijaviti sa ovim podacima."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}

