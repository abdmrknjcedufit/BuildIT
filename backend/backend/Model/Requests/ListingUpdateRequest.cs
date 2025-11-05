namespace BuildIT.Model.Requests
{
    public class ListingUpdateRequest
    {
        public int? ItemId { get; set; }
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? ListingType { get; set; }
        public string? Status { get; set; }
        public int? CityId { get; set; }
        public bool? IsFeatured { get; set; }
        public string? Images { get; set; }
    }
}

