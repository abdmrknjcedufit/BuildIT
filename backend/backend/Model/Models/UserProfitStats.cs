namespace BuildIT.Model.Models
{
    public class UserProfitStats
    {
        public decimal TotalProfit { get; set; }
        public int TotalSales { get; set; }
        public List<DailyProfit> DailyProfits { get; set; } = new();
        public List<MonthlyProfit> MonthlyProfits { get; set; } = new();
    }

    public class DailyProfit
    {
        public string Date { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public int SalesCount { get; set; }
    }

    public class MonthlyProfit
    {
        public string Month { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public int SalesCount { get; set; }
    }
}

