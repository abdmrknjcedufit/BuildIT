using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using BuildIT.Services.Database;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [AllowAnonymous]
    public class UserController : BaseCRUDController<BuildIT.Model.Models.User, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        protected new IUserService _service;
        private readonly ILogger<UserController> _logger;
        
        public UserController(IUserService service, ILogger<UserController> logger) : base(service)
        {
            _service = service;
            _logger = logger;
        }

        [AllowAnonymous]
        public override BuildIT.Model.Models.User Insert(UserInsertRequest request)
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

        [HttpPost("logout")]
        public IActionResult Logout()
        {
            var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            var username = User.Identity?.Name;

            return Ok(new { 
                message = "Uspješno ste se odjavili.",
                userId = userIdClaim,
                username = username
            });
        }

        [HttpPost("forgot-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            try
            {
                var message = await _service.ForgotPasswordAsync(request.Email, request.Phone);
                return Ok(new { 
                    message = message
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("reset-password")]
        [AllowAnonymous]
        public async Task<IActionResult> ResetPasswordWithToken([FromBody] ResetPasswordWithTokenRequest request)
        {
            try
            {
                await _service.ResetPasswordWithTokenAsync(request.Token, request.NewPassword);
                return Ok(new { 
                    message = "Lozinka je uspješno resetovana. Sada se možete prijaviti."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
                if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                    return Unauthorized(new { message = "Korisnik nije prijavljen." });

                var message = await _service.ChangePasswordAsync(userId, request.OldPassword, request.NewPassword, request.NewPasswordConfirm);
                return Ok(new { 
                    message = message
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
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

        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
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

            if (!userRoles.Contains("Admin"))
            {
                return StatusCode(403, new { message = "Samo administratori mogu deaktivirati/aktivirati korisnike. Nemate dozvolu za ovu akciju." });
            }

            try
            {
                _service.DeleteUser(id);
                return Ok(new { message = "Korisnik je uspješno deaktiviran/aktiviran." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/reviews")]
        [AllowAnonymous]
        public IActionResult GetUserReviews(int id, [FromServices] BuildITDbContext context)
        {
            try
            {
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Počinje za userId={id}");

                var userListingIdsFromListings = context.Listings
                    .Where(l => l.UserId == id)
                    .Select(l => l.Id)
                    .ToList();
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Listing IDs direktno (UserId={id}): [{string.Join(", ", userListingIdsFromListings)}]");

                var userListingIdsFromTransactions = context.Transactions
                    .Where(t => t.SellerId == id)
                    .Select(t => t.ListingId)
                    .Distinct()
                    .ToList();
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Listing IDs iz transakcija (SellerId={id}): [{string.Join(", ", userListingIdsFromTransactions)}]");

                var userItemIds = context.Items
                    .Where(i => i.UserId == id)
                    .Select(i => i.Id)
                    .ToList();
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Item IDs (UserId={id}): [{string.Join(", ", userItemIds)}]");

                var allListingIds = userListingIdsFromListings
                    .Union(userListingIdsFromTransactions)
                    .ToList();
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Sve Listing IDs (union): [{string.Join(", ", allListingIds)}]");

                var allTargetIds = allListingIds.Union(userItemIds).ToList();
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Svi Target IDs (listing + item): [{string.Join(", ", allTargetIds)}]");

                if (!allTargetIds.Any())
                {
                    _logger.LogWarning($"⚠️ GET-USER-REVIEWS: Nema Target IDs za userId={id}, vraćam prazan rezultat");
                    return Ok(new 
                    { 
                        reviews = new List<object>(),
                        averageRating = 0.0, 
                        totalReviews = 0 
                    });
                }

                var reviews = context.Reviews
                    .Include(r => r.Reviewer)
                    .Where(r => r.TargetType == "Item" &&
                                allTargetIds.Contains(r.TargetId))
                    .OrderByDescending(r => r.CreatedAt)
                    .ToList();
                
                _logger.LogInformation($"🔵 GET-USER-REVIEWS: Pronađeno {reviews.Count} review-a za Target IDs: [{string.Join(", ", allTargetIds)}]");
                foreach (var r in reviews)
                {
                    _logger.LogInformation($"  - Review ID={r.Id}, TargetId={r.TargetId}, Rating={r.Rating}, IsApproved={r.IsApproved}, Comment={r.Comment ?? "N/A"}, ReviewerId={r.ReviewerId}, Reviewer={r.Reviewer?.FirstName} {r.Reviewer?.LastName}");
                }

                var reviewList = reviews.Select(r => new
                {
                    id = r.Id,
                    reviewerId = r.ReviewerId,
                    reviewer = new
                    {
                        id = r.Reviewer.Id,
                        firstName = r.Reviewer.FirstName,
                        lastName = r.Reviewer.LastName,
                        username = r.Reviewer.Username
                    },
                    rating = r.Rating,
                    comment = r.Comment,
                    transactionId = r.TransactionId,
                    createdAt = r.CreatedAt,
                    updatedAt = r.UpdatedAt
                }).ToList();

                double averageRating = 0.0;
                if (reviews.Any())
                {
                    averageRating = Math.Round(reviews.Average(r => r.Rating), 2);
                }

                _logger.LogInformation($"✅ GET-USER-REVIEWS: Završeno za userId={id}, reviews={reviews.Count}, averageRating={averageRating}");
                
                return Ok(new 
                { 
                    reviews = reviewList,
                    averageRating = averageRating, 
                    totalReviews = reviews.Count 
                });
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ GET-USER-REVIEWS: Greška za userId={id}: {ex.Message}");
                _logger.LogError($"❌ GET-USER-REVIEWS: Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ GET-USER-REVIEWS: Inner exception: {ex.InnerException.Message}");
                }
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/average-rating")]
        [AllowAnonymous]
        public IActionResult GetAverageRating(int id, [FromServices] BuildITDbContext context)
        {
            try
            {
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Počinje za userId={id}");

                var userListingIdsFromListings = context.Listings
                    .Where(l => l.UserId == id)
                    .Select(l => l.Id)
                    .ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Listing IDs direktno: [{string.Join(", ", userListingIdsFromListings)}]");

                var userListingIdsFromTransactions = context.Transactions
                    .Where(t => t.SellerId == id)
                    .Select(t => t.ListingId)
                    .Distinct()
                    .ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Listing IDs iz transakcija: [{string.Join(", ", userListingIdsFromTransactions)}]");

                var userItemIds = context.Items
                    .Where(i => i.UserId == id)
                    .Select(i => i.Id)
                    .ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Item IDs: [{string.Join(", ", userItemIds)}]");

                var allListingIds = userListingIdsFromListings
                    .Union(userListingIdsFromTransactions)
                    .ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Sve Listing IDs: [{string.Join(", ", allListingIds)}]");

                var allTargetIds = allListingIds.Union(userItemIds).ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Svi Target IDs: [{string.Join(", ", allTargetIds)}]");

                if (!allTargetIds.Any())
                {
                    _logger.LogWarning($"⚠️ GET-AVERAGE-RATING: Nema Target IDs za userId={id}");
                    return Ok(new { averageRating = 0.0, totalReviews = 0 });
                }

                var reviews = context.Reviews
                    .Where(r => r.TargetType == "Item" &&
                                allTargetIds.Contains(r.TargetId))
                    .ToList();
                _logger.LogInformation($"🔵 GET-AVERAGE-RATING: Pronađeno {reviews.Count} review-a");

                if (!reviews.Any())
                {
                    _logger.LogInformation($"⚠️ GET-AVERAGE-RATING: Nema odobrenih review-a za userId={id}");
                    return Ok(new { averageRating = 0.0, totalReviews = 0 });
                }

                var averageRating = reviews.Average(r => r.Rating);
                var totalReviews = reviews.Count;
                _logger.LogInformation($"✅ GET-AVERAGE-RATING: Završeno za userId={id}, averageRating={Math.Round(averageRating, 2)}, totalReviews={totalReviews}");

                return Ok(new { averageRating = Math.Round(averageRating, 2), totalReviews });
            }
            catch (Exception ex)
            {
                _logger.LogError($"❌ GET-AVERAGE-RATING: Greška za userId={id}: {ex.Message}");
                _logger.LogError($"❌ GET-AVERAGE-RATING: Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ GET-AVERAGE-RATING: Inner exception: {ex.InnerException.Message}");
                }
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("two-factor/generate")]
        [AllowAnonymous]
        public async Task<IActionResult> GenerateTwoFactorCode([FromBody] TwoFactorRequest request)
        {
            try
            {
                var user = _service.Login(request.Username, request.Password);
                if (user == null)
                {
                    return BadRequest(new { message = "Neispravno korisničko ime ili lozinka." });
                }

                if (request.TwoFactorMethod != null)
                {
                    await _service.GenerateTwoFactorCodeAsync(request.Username);
                }
                else
                {
                    await _service.GenerateTwoFactorCodeAsync(request.Username);
                }

                return Ok(new { message = "Kod za dvofaktorsku autentifikaciju je poslan." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("two-factor/verify")]
        [AllowAnonymous]
        public async Task<IActionResult> VerifyTwoFactor([FromBody] VerifyTwoFactorRequest request, [FromServices] BuildITDbContext context)
        {
            try
            {
                var isValid = await _service.VerifyTwoFactorCodeAsync(request.Username, request.Code);
                if (isValid)
                {
                    var user = context.Users
                        .Include(u => u.UserRoles)
                        .ThenInclude(ur => ur.Role)
                        .FirstOrDefault(u => u.Username == request.Username);

                    if (user == null)
                        return BadRequest(new { message = "Korisnik nije pronađen." });

                    var userModel = new BuildIT.Model.Models.User
                    {
                        Id = user.Id,
                        Username = user.Username,
                        Email = user.Email,
                        FirstName = user.FirstName,
                        LastName = user.LastName,
                        Phone = user.Phone,
                        Roles = user.UserRoles.Select(ur => ur.Role.Name).ToList()
                    };

                    return Ok(new { message = "2FA kod je validan.", user = userModel });
                }

                return BadRequest(new { message = "Kod nije validan." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/two-factor/enable")]
        [Authorize]
        public async Task<IActionResult> EnableTwoFactor(int id, [FromBody] EnableTwoFactorRequest request)
        {
            try
            {
                var message = await _service.EnableTwoFactorAsync(id, request.Method);
                return Ok(new { message });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/two-factor/disable")]
        [Authorize]
        public async Task<IActionResult> DisableTwoFactor(int id)
        {
            try
            {
                await _service.DisableTwoFactorAsync(id);
                return Ok(new { message = "Dvofaktorska autentifikacija je onemogućena." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/profit")]
        [Authorize]
        public IActionResult GetUserProfit(int id, [FromServices] BuildITDbContext context)
        {
            try
            {
                var completedTransactions = context.Transactions
                    .Where(t => t.SellerId == id && t.Status == "Completed")
                    .ToList();

                var totalProfit = completedTransactions.Sum(t => (decimal?)t.Amount) ?? 0;
                var totalSales = completedTransactions.Count;

                var last30Days = Enumerable.Range(0, 30)
                    .Select(i => DateTime.Now.AddDays(-i).Date)
                    .Reverse()
                    .ToList();

                var dailyProfits = last30Days.Select(day => new BuildIT.Model.Models.DailyProfit
                {
                    Date = day.ToString("yyyy-MM-dd"),
                    Amount = completedTransactions
                        .Where(t => t.TransactionDate.Date == day)
                        .Sum(t => (decimal?)t.Amount) ?? 0,
                    SalesCount = completedTransactions
                        .Where(t => t.TransactionDate.Date == day)
                        .Count()
                }).ToList();

                var last12Months = Enumerable.Range(0, 12)
                    .Select(i => DateTime.Now.AddMonths(-i))
                    .Reverse()
                    .ToList();

                var monthlyProfits = last12Months.Select(month => new BuildIT.Model.Models.MonthlyProfit
                {
                    Month = month.ToString("yyyy-MM"),
                    Amount = completedTransactions
                        .Where(t => t.TransactionDate.Year == month.Year && t.TransactionDate.Month == month.Month)
                        .Sum(t => (decimal?)t.Amount) ?? 0,
                    SalesCount = completedTransactions
                        .Where(t => t.TransactionDate.Year == month.Year && t.TransactionDate.Month == month.Month)
                        .Count()
                }).ToList();

                var stats = new BuildIT.Model.Models.UserProfitStats
                {
                    TotalProfit = totalProfit,
                    TotalSales = totalSales,
                    DailyProfits = dailyProfits,
                    MonthlyProfits = monthlyProfits
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}

