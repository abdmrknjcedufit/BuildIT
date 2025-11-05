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
    }
}

