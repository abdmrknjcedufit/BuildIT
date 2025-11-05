namespace BuildIT.Model.SearchObjects
{
    public class TransactionSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? ListingId { get; set; }
        public int? BuyerId { get; set; }
        public int? SellerId { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
        public decimal? MinAmount { get; set; }
        public decimal? MaxAmount { get; set; }
        public string? Status { get; set; }
        public string? Type { get; set; }
        public string? PaymentMethod { get; set; }
    }
}

