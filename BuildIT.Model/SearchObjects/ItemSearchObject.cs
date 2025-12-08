namespace BuildIT.Model.SearchObjects
{
    public class ItemSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public string? ItemType { get; set; }
        public string? Status { get; set; }
        public string? Condition { get; set; }
        public int? CompanyId { get; set; }
        public int? UserId { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsAvailable { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? Brand { get; set; }
    }
}

