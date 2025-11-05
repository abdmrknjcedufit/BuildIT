namespace BuildIT.Model.Requests
{
    public class ListingInsertRequest
    {
        public int ItemId { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string ListingType { get; set; } = null!;
        public string Status { get; set; } = "Active";
        public int? CityId { get; set; }
        public bool IsFeatured { get; set; } = false;
        public string? Images { get; set; }
    }
}

