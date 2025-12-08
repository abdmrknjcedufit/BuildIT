namespace BuildIT.Model.Models
{
    public class DashboardStats
    {
        public int TotalUsers { get; set; }
        public int TotalOrders { get; set; }
        public decimal TotalRevenue { get; set; }
        public int ActiveRentals { get; set; }
        public List<MonthlyData> RevenueTrend { get; set; } = new();
        public List<MonthlyData> OrderTrend { get; set; } = new();
        public List<CategoryDistribution> ProductDistribution { get; set; } = new();
    }

    public class StatisticsData
    {
        public decimal AverageOrderValue { get; set; }
        public decimal ConversionRate { get; set; }
        public decimal UserRetention { get; set; }
        public decimal AverageDeliveryTime { get; set; }
        public List<MonthlyOrderData> MonthlyOrders { get; set; } = new();
        public List<BestSellingItem> BestSellingItems { get; set; } = new();
    }

    public class MonthlyData
    {
        public string Month { get; set; } = null!;
        public decimal Value { get; set; }
    }

    public class MonthlyOrderData
    {
        public string Month { get; set; } = null!;
        public int Completed { get; set; }
        public int Pending { get; set; }
    }

    public class BestSellingItem
    {
        public string Name { get; set; } = null!;
        public int SalesCount { get; set; }
    }

    public class CategoryDistribution
    {
        public string Category { get; set; } = null!;
        public decimal Percentage { get; set; }
    }
}

