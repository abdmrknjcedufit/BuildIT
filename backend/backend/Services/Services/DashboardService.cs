using BuildIT.Model.Models;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace BuildIT.Services.Services
{
    public class DashboardService : IDashboardService
    {
        protected BuildITDbContext Context { get; set; }

        public DashboardService(BuildITDbContext context)
        {
            Context = context;
        }

        public DashboardStats GetDashboardStats()
        {
            var stats = new DashboardStats();

            stats.TotalUsers = Context.Users
                .Where(u => u.IsActive)
                .Count();

            stats.TotalOrders = Context.Orders.Count();

            stats.TotalRevenue = Context.Transactions
                .Where(t => t.Status == "Completed")
                .Sum(t => (decimal?)t.Amount) ?? 0;

            stats.ActiveRentals = Context.Listings
                .Where(l => l.ListingType == "Iznajmljivanje" && l.Status == "Active")
                .Count();

            var last7Months = Enumerable.Range(0, 7)
                .Select(i => DateTime.Now.AddMonths(-i))
                .Reverse()
                .ToList();

            stats.RevenueTrend = last7Months.Select(month => new MonthlyData
            {
                Month = month.ToString("MMM"),
                Value = Context.Transactions
                    .Where(t => t.Status == "Completed" &&
                                t.TransactionDate.Year == month.Year &&
                                t.TransactionDate.Month == month.Month)
                    .Sum(t => (decimal?)t.Amount) ?? 0
            }).ToList();

            stats.OrderTrend = last7Months.Select(month => new MonthlyData
            {
                Month = month.ToString("MMM"),
                Value = Context.Orders
                    .Where(o => o.CreatedAt.Year == month.Year &&
                                o.CreatedAt.Month == month.Month)
                    .Count()
            }).ToList();

            var totalItems = Context.Items.Count();
            if (totalItems > 0)
            {
                stats.ProductDistribution = Context.Items
                    .Include(i => i.Category)
                    .GroupBy(i => i.Category != null ? i.Category.Description : "Ostalo")
                    .Select(g => new CategoryDistribution
                    {
                        Category = g.Key,
                        Percentage = Math.Round((decimal)g.Count() / totalItems * 100, 1)
                    })
                    .ToList();
            }

            return stats;
        }

        public StatisticsData GetStatisticsData()
        {
            var stats = new StatisticsData();

            var completedOrdersForAvg = Context.Orders
                .Where(o => o.Status == "Completed")
                .ToList();
            
            stats.AverageOrderValue = completedOrdersForAvg.Any()
                ? completedOrdersForAvg.Average(o => o.FinalAmount)
                : 0;

            var totalVisitors = Context.Users.Count();
            var convertedUsers = Context.Users
                .Where(u => Context.Orders.Any(o => o.UserId == u.Id))
                .Count();
            
            stats.ConversionRate = totalVisitors > 0
                ? Math.Round((decimal)convertedUsers / totalVisitors * 100, 2)
                : 0;

            var activeUsers = Context.Users
                .Where(u => u.IsActive && 
                           Context.Orders.Any(o => o.UserId == u.Id && 
                                                  o.CreatedAt >= DateTime.Now.AddMonths(-1)))
                .Count();
            
            var previousMonthActiveUsers = Context.Users
                .Where(u => u.IsActive && 
                           Context.Orders.Any(o => o.UserId == u.Id && 
                                                  o.CreatedAt >= DateTime.Now.AddMonths(-2) &&
                                                  o.CreatedAt < DateTime.Now.AddMonths(-1)))
                .Count();

            stats.UserRetention = previousMonthActiveUsers > 0
                ? Math.Round((decimal)activeUsers / previousMonthActiveUsers * 100, 1)
                : 0;

            var completedOrdersWithDelivery = Context.Orders
                .Where(o => o.Status == "Completed" && o.ExpectedDeliveryDate.HasValue)
                .ToList();
            
            if (completedOrdersWithDelivery.Any())
            {
                var avgDeliveryDays = completedOrdersWithDelivery
                    .Select(o => (o.ExpectedDeliveryDate!.Value - o.CreatedAt).TotalDays)
                    .Average();
                stats.AverageDeliveryTime = (decimal)Math.Round(avgDeliveryDays, 1);
            }
            else
            {
                stats.AverageDeliveryTime = 0;
            }

            var last6Months = Enumerable.Range(0, 6)
                .Select(i => DateTime.Now.AddMonths(-i))
                .Reverse()
                .ToList();

            stats.MonthlyOrders = last6Months.Select(month => new MonthlyOrderData
            {
                Month = month.ToString("MMM"),
                Completed = Context.Orders
                    .Where(o => o.Status == "Completed" &&
                               o.CreatedAt.Year == month.Year &&
                               o.CreatedAt.Month == month.Month)
                    .Count(),
                Pending = Context.Orders
                    .Where(o => o.Status == "Pending" &&
                               o.CreatedAt.Year == month.Year &&
                               o.CreatedAt.Month == month.Month)
                    .Count()
            }).ToList();

            stats.BestSellingItems = Context.Items
                .OrderByDescending(i => i.TotalOrders)
                .Take(5)
                .Select(i => new BestSellingItem
                {
                    Name = i.Title,
                    SalesCount = i.TotalOrders
                })
                .ToList();

            return stats;
        }
    }
}

