namespace BuildIT.Model.Models
{
    public class Item
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Price { get; set; }
        public string ItemType { get; set; } = null!;
        public string Status { get; set; } = null!;
        public string Condition { get; set; } = null!;
        public int? CompanyId { get; set; }
        public int? CategoryId { get; set; }
        public int? MinRentalPeriod { get; set; }
        public int? MaxRentalPeriod { get; set; }
        public string? Brand { get; set; }
        public string? Model { get; set; }
        public int? Year { get; set; }
        public DateTime? AvailabilityDate { get; set; }
        public int TotalPurchases { get; set; }
        public int TotalRentals { get; set; }
        public int TotalOrders { get; set; }
        public DateTime? LastSoldDate { get; set; }
        public DateTime? LastRentedDate { get; set; }
        public bool IsAvailable { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}

