using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ReviewModel = BuildIT.Model.Models.Review;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReviewController : BaseCRUDController<ReviewModel, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        protected new IReviewService _service;
        private readonly BuildITDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly ILogger<ReviewController> _logger;

        public ReviewController(IReviewService service, BuildITDbContext context, INotificationService notificationService, ILogger<ReviewController> logger) : base(service)
        {
            _service = service;
            _context = context;
            _notificationService = notificationService;
            _logger = logger;
        }

        [HttpPost]
        public override ReviewModel Insert(ReviewInsertRequest request)
        {
            _logger.LogInformation($"🔵 REVIEW-INSERT: Počinje kreiranje review-a - TargetType={request.TargetType}, TargetId={request.TargetId}, ReviewerId={request.ReviewerId}, Rating={request.Rating}");
            
            var review = _service.Insert(request);
            _logger.LogInformation($"✅ REVIEW-INSERT: Review kreiran! ReviewId={review.Id}");

            try
            {
                _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: Provjeravam TargetType... TargetType={request.TargetType}");
                
                if (request.TargetType == "Item" || request.TargetType == "Listing")
                {
                    _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: TargetType je validan, tražim listing sa TargetId={request.TargetId}");
                    
                    var listing = _context.Listings
                        .Include(l => l.User)
                        .FirstOrDefault(l => l.Id == request.TargetId);

                    if (listing == null)
                    {
                        _logger.LogWarning($"⚠️ REVIEW-NOTIFICATION: Listing sa Id={request.TargetId} nije pronađen!");
                    }
                    else
                    {
                        _logger.LogInformation($"✅ REVIEW-NOTIFICATION: Listing pronađen! ListingId={listing.Id}, Listing.UserId={listing.UserId}, ReviewerId={request.ReviewerId}");
                        
                        if (listing.UserId == request.ReviewerId)
                        {
                            _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: Listing.UserId ({listing.UserId}) == ReviewerId ({request.ReviewerId}), preskačem notifikaciju (korisnik ocjenjuje svoj artikal)");
                        }
                        else
                        {
                            _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: Listing.UserId ({listing.UserId}) != ReviewerId ({request.ReviewerId}), kreiram notifikaciju...");
                            
                            var reviewer = _context.Users.FirstOrDefault(u => u.Id == request.ReviewerId);
                            var reviewerName = reviewer != null ? $"{reviewer.FirstName} {reviewer.LastName}".Trim() : "Korisnik";
                            var listingTitle = listing.Title ?? "Nepoznat artikal";

                            _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: ReviewerName={reviewerName}, ListingTitle={listingTitle}");

                            var notificationRequest = new NotificationInsertRequest
                            {
                                UserId = listing.UserId,
                                Title = "⭐ Nova ocjena za vaš artikal!",
                                Message = $"Korisnik {reviewerName} je ostavio ocjenu {request.Rating}/5 za vaš artikal \"{listingTitle}\".",
                                NotificationType = "Review",
                                ReferenceId = review.Id,
                                Priority = "Normal",
                                IsRead = false,
                                IsSent = true
                            };

                            _logger.LogInformation($"🔵 REVIEW-NOTIFICATION: Pozivam _notificationService.Insert... UserId={listing.UserId}, NotificationType=Review, ReferenceId={review.Id}");
                            
                            var notification = _notificationService.Insert(notificationRequest);
                            _logger.LogInformation($"✅ REVIEW-NOTIFICATION: Notifikacija kreirana! NotificationId={notification.Id}, UserId={listing.UserId}");
                        }
                    }
                }
                else
                {
                    _logger.LogWarning($"⚠️ REVIEW-NOTIFICATION: TargetType '{request.TargetType}' nije 'Item' ili 'Listing', preskačem kreiranje notifikacije");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ REVIEW-NOTIFICATION: Greška pri kreiranju notifikacije: {ex.Message}");
                _logger.LogError($"❌ REVIEW-NOTIFICATION: Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ REVIEW-NOTIFICATION: Inner exception: {ex.InnerException.Message}");
                }
            }

            return review;
        }
    }
}

