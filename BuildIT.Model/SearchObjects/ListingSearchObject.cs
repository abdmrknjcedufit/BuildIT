namespace BuildIT.Model.SearchObjects
{
    public class ListingSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? ItemId { get; set; }
        public int? UserId { get; set; }
        public string? ListingType { get; set; }
        public string? Status { get; set; }
        public int? CityId { get; set; }
        public bool? IsFeatured { get; set; }
    }
}

