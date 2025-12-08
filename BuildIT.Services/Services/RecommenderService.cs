using BuildIT.Model.Models;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.ML;
using ListingModel = BuildIT.Model.Models.Listing;
using ListingDb = BuildIT.Services.Database.Listing;
using ItemModel = BuildIT.Model.Models.Item;
using ItemDb = BuildIT.Services.Database.Item;
using CityModel = BuildIT.Model.Models.City;
using CityDb = BuildIT.Services.Database.City;

namespace BuildIT.Services.Services
{
    public class RecommenderService : IRecommenderService
    {
        private readonly BuildITDbContext _context;
        private MLContext _mlContext;

        public RecommenderService(BuildITDbContext context)
        {
            _context = context;
            _mlContext = new MLContext();
        }

        public List<ListingModel> GetRecommendations(int userId, int count = 10)
        {
            try
            {
                var userOrders = _context.Orders
                    .Include(o => o.Transaction)
                        .ThenInclude(t => t.Listing)
                            .ThenInclude(l => l.Item)
                                .ThenInclude(i => i.Category)
                    .Include(o => o.Transaction)
                        .ThenInclude(t => t.Listing)
                            .ThenInclude(l => l.City)
                    .Where(o => o.UserId == userId && o.Status == "Completed" && o.Transaction != null)
                    .Select(o => o.Transaction.Listing)
                    .Where(l => l != null)
                    .Cast<ListingDb>()
                    .Distinct()
                    .ToList();

                if (!userOrders.Any())
                {
                    return GetPopularListings(count);
                }

                var userPreferences = ExtractUserPreferences(userOrders, userId);

                var allListings = _context.Listings
                    .Include(l => l.Item)
                        .ThenInclude(i => i.Category)
                    .Include(l => l.City)
                    .Include(l => l.User)
                    .Where(l => l.Status == "Active" && l.Item != null && l.UserId != userId)
                    .ToList();

                var recommendations = allListings
                    .Select(listing => new
                    {
                        Listing = listing,
                        Score = CalculateSimilarityScore(listing, userPreferences, userId)
                    })
                    .Where(x => x.Score > 0)
                    .OrderByDescending(x => x.Score)
                    .Take(count)
                    .Select(x => MapToListingModel(x.Listing))
                    .ToList();

                return recommendations;
            }
            catch
            {
                return GetPopularListings(count);
            }
        }

        private UserPreferences ExtractUserPreferences(List<ListingDb> userOrders, int userId)
        {
            var preferences = new UserPreferences();

            var categoryIds = userOrders
                .Where(l => l.Item?.CategoryId != null)
                .GroupBy(l => l.Item.CategoryId.Value)
                .OrderByDescending(g => g.Count())
                .Take(3)
                .Select(g => g.Key)
                .ToList();
            preferences.PreferredCategoryIds = categoryIds;

            var listingTypes = userOrders
                .GroupBy(l => l.ListingType)
                .OrderByDescending(g => g.Count())
                .Select(g => g.Key)
                .ToList();
            preferences.PreferredListingTypes = listingTypes;

            var prices = userOrders
                .Where(l => l.Item != null)
                .Select(l => (double)l.Item.Price)
                .ToList();
            if (prices.Any())
            {
                preferences.AveragePrice = prices.Average();
                preferences.MinPrice = prices.Min();
                preferences.MaxPrice = prices.Max();
            }

            var user = _context.Users
                .Include(u => u.City)
                .FirstOrDefault(u => u.Id == userId);
            
            if (user?.CityId != null)
            {
                preferences.UserCityId = user.CityId.Value;
            }

            var itemTypes = userOrders
                .Where(l => l.Item != null && !string.IsNullOrEmpty(l.Item.ItemType))
                .GroupBy(l => l.Item.ItemType)
                .OrderByDescending(g => g.Count())
                .Take(3)
                .Select(g => g.Key)
                .ToList();
            preferences.PreferredItemTypes = itemTypes;

            return preferences;
        }

        private double CalculateSimilarityScore(ListingDb listing, UserPreferences preferences, int userId)
        {
            double score = 0.0;

            if (listing.Item?.CategoryId != null && preferences.PreferredCategoryIds.Contains(listing.Item.CategoryId.Value))
            {
                score += 0.4;
            }

            if (preferences.PreferredListingTypes.Contains(listing.ListingType))
            {
                score += 0.2;
            }

            if (listing.Item != null && !string.IsNullOrEmpty(listing.Item.ItemType) &&
                preferences.PreferredItemTypes.Contains(listing.Item.ItemType))
            {
                score += 0.15;
            }

            if (listing.Item != null && preferences.AveragePrice > 0)
            {
                var priceDiff = Math.Abs((double)listing.Item.Price - preferences.AveragePrice);
                var maxPrice = Math.Max(preferences.MaxPrice, (double)listing.Item.Price);
                if (maxPrice > 0)
                {
                    var priceSimilarity = 1.0 - (priceDiff / maxPrice);
                    score += 0.15 * Math.Max(0, priceSimilarity);
                }
            }

            if (preferences.UserCityId.HasValue && listing.CityId.HasValue)
            {
                if (preferences.UserCityId.Value == listing.CityId.Value)
                {
                    score += 0.1;
                }
                else
                {
                    score += 0.05;
                }
            }

            if (listing.IsFeatured)
            {
                score += 0.1;
            }

            return score;
        }

        private List<ListingModel> GetPopularListings(int count)
        {
            return _context.Listings
                .Include(l => l.Item)
                    .ThenInclude(i => i.Category)
                .Include(l => l.City)
                .Include(l => l.User)
                .Where(l => l.Status == "Active" && l.Item != null)
                .OrderByDescending(l => l.IsFeatured)
                .ThenByDescending(l => l.Item.TotalOrders)
                .Take(count)
                .Select(l => MapToListingModel(l))
                .ToList();
        }

        private ListingModel MapToListingModel(ListingDb listing)
        {
            return new ListingModel
            {
                Id = listing.Id,
                ItemId = listing.ItemId,
                UserId = listing.UserId,
                Title = listing.Title,
                Description = listing.Description,
                ListingType = listing.ListingType,
                Status = listing.Status,
                CityId = listing.CityId,
                IsFeatured = listing.IsFeatured,
                CreatedAt = listing.CreatedAt,
                UpdatedAt = listing.UpdatedAt,
                Images = listing.Images,
                MinRentalDays = listing.MinRentalDays,
                MaxRentalDays = listing.MaxRentalDays,
                Item = listing.Item != null ? new ItemModel
                {
                    Id = listing.Item.Id,
                    Title = listing.Item.Title,
                    Description = listing.Item.Description,
                    Price = listing.Item.Price,
                    ItemType = listing.Item.ItemType,
                    Status = listing.Item.Status,
                    Condition = listing.Item.Condition,
                    CategoryId = listing.Item.CategoryId,
                    Brand = listing.Item.Brand,
                    Model = listing.Item.Model,
                    Year = listing.Item.Year,
                    TotalOrders = listing.Item.TotalOrders,
                    TotalRentals = listing.Item.TotalRentals,
                    TotalPurchases = listing.Item.TotalPurchases,
                } : null,
                City = listing.City != null ? new CityModel
                {
                    Id = listing.City.Id,
                    Name = listing.City.Name,
                    IsActive = listing.City.IsActive
                } : null
            };
        }

        private class UserPreferences
        {
            public List<int> PreferredCategoryIds { get; set; } = new();
            public List<string> PreferredListingTypes { get; set; } = new();
            public List<string> PreferredItemTypes { get; set; } = new();
            public double AveragePrice { get; set; }
            public double MinPrice { get; set; }
            public double MaxPrice { get; set; }
            public int? UserCityId { get; set; }
        }
    }
}

