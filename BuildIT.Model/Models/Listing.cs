namespace BuildIT.Model.Models
{
    public class Listing
    {
        public int Id { get; set; }
        public int ItemId { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string ListingType { get; set; } = null!;
        public string Status { get; set; } = null!;
        public int? CityId { get; set; }
        public bool IsFeatured { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public string? Images { get; set; }
        public int? MinRentalDays { get; set; }
        public int? MaxRentalDays { get; set; }
        public Item? Item { get; set; }
        public User? User { get; set; }
        public City? City { get; set; }
    }
}

