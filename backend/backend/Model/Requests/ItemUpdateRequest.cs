namespace BuildIT.Model.Requests
{
    public class ItemUpdateRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public decimal? Price { get; set; }
        public string? ItemType { get; set; }
        public string? Status { get; set; }
        public string? Condition { get; set; }
        public int? CompanyId { get; set; }
        public int? CategoryId { get; set; }
        public int? MinRentalPeriod { get; set; }
        public int? MaxRentalPeriod { get; set; }
        public string? Brand { get; set; }
        public string? Model { get; set; }
        public int? Year { get; set; }
        public DateTime? AvailabilityDate { get; set; }
        public bool? IsAvailable { get; set; }
        public int? TotalPurchases { get; set; }
        public int? TotalRentals { get; set; }
        public int? TotalOrders { get; set; }
        public DateTime? LastSoldDate { get; set; }
        public DateTime? LastRentedDate { get; set; }
    }
}

