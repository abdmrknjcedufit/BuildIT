namespace BuildIT.Model.Requests
{
    public class TransactionInsertRequest
    {
        public int ListingId { get; set; }
        public int BuyerId { get; set; }
        public int SellerId { get; set; }
        public decimal Amount { get; set; }
        public string Status { get; set; } = "Pending";
        public string PaymentMethod { get; set; } = null!;
        public string Type { get; set; } = "Payment";
        public DateTime TransactionDate { get; set; }
        public string? StripeTransactionId { get; set; }
    }
}

