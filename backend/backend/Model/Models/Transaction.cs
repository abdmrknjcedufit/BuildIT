namespace BuildIT.Model.Models
{
    public class Transaction
    {
        public int Id { get; set; }
        public int ListingId { get; set; }
        public int BuyerId { get; set; }
        public int SellerId { get; set; }
        public decimal Amount { get; set; }
        public string Status { get; set; } = null!;
        public string PaymentMethod { get; set; } = null!;
        public string Type { get; set; } = null!;
        public DateTime TransactionDate { get; set; }
        public string? StripeTransactionId { get; set; }
        public DateTime CreatedAt { get; set; }
        public Listing? Listing { get; set; }
        public User? Seller { get; set; }
    }
}

