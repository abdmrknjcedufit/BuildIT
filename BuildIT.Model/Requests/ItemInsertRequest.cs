namespace BuildIT.Model.Requests
{
    public class ItemInsertRequest
    {
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public decimal Price { get; set; }
        public string ItemType { get; set; } = null!;
        public string Status { get; set; } = "Available";
        public string Condition { get; set; } = null!;
        public int? CompanyId { get; set; }
        public int? UserId { get; set; }
        public int? CategoryId { get; set; }
        public int? MinRentalPeriod { get; set; }
        public int? MaxRentalPeriod { get; set; }
        public string? Brand { get; set; }
        public string? Model { get; set; }
        public int? Year { get; set; }
        public DateTime? AvailabilityDate { get; set; }
        public string? Images { get; set; }
    }
}

