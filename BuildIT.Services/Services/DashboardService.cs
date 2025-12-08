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

            // Prosječna vrijednost narudžbe
            // Računamo prosjek svih narudžbi koje imaju FinalAmount > 0
            var ordersForAvg = Context.Orders
                .Where(o => o.FinalAmount > 0)
                .ToList();
            
            if (ordersForAvg.Any())
            {
                stats.AverageOrderValue = Math.Round(ordersForAvg.Average(o => o.FinalAmount), 2);
            }
            else
            {
                // Ako nema narudžbi sa FinalAmount, probajmo sa TotalAmount
                var ordersWithTotal = Context.Orders
                    .Where(o => o.TotalAmount > 0)
                    .ToList();
                
                stats.AverageOrderValue = ordersWithTotal.Any()
                    ? Math.Round(ordersWithTotal.Average(o => o.TotalAmount), 2)
                    : 0;
            }

            // Ukupan prihod
            stats.TotalRevenue = Context.Transactions
                .Where(t => t.Status == "Completed")
                .Sum(t => (decimal?)t.Amount) ?? 0;

            // Ukupan broj narudžbi
            stats.TotalOrders = Context.Orders.Count();

            // Broj aktivnih korisnika
            stats.TotalActiveUsers = Context.Users
                .Where(u => u.IsActive)
                .Count();

            // Broj aktivnih oglasa
            stats.TotalActiveListings = Context.Listings
                .Where(l => l.Status == "Active")
                .Count();

            // Prosječan broj stavki po narudžbi
            // Računamo prosječan broj stavki u korpi za korisnike koji imaju completed narudžbe
            var completedOrdersCount = Context.Orders
                .Where(o => o.Status == "Completed")
                .Count();
            
            if (completedOrdersCount > 0)
            {
                // Izračunajmo prosječan broj stavki preko Cart-a za korisnike sa completed narudžbama
                var usersWithOrders = Context.Orders
                    .Where(o => o.Status == "Completed")
                    .Select(o => o.UserId)
                    .Distinct()
                    .ToList();
                
                if (usersWithOrders.Any())
                {
                    var totalCartItemsForUsers = Context.Carts
                        .Where(c => usersWithOrders.Contains(c.UserId))
                        .Sum(c => (int?)c.Quantity) ?? 0;
                    
                    stats.AverageItemsPerOrder = totalCartItemsForUsers > 0
                        ? Math.Round((decimal)totalCartItemsForUsers / completedOrdersCount, 2)
                        : 1.0m;
                }
                else
                {
                    stats.AverageItemsPerOrder = 1.0m;
                }
            }
            else
            {
                stats.AverageItemsPerOrder = 0;
            }

            // Prosječna ocjena
            var reviews = Context.Reviews
                .Where(r => r.Rating > 0)
                .ToList();
            
            if (reviews.Any())
            {
                stats.AverageRating = Math.Round((decimal)reviews.Average(r => r.Rating), 2);
            }
            else
            {
                stats.AverageRating = 0;
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

