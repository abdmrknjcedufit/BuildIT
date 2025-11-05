namespace BuildIT.Model.Requests
{
    public class TransactionUpdateRequest
    {
        public string? Status { get; set; }
        public string? PaymentMethod { get; set; }
        public string? StripeTransactionId { get; set; }
    }
}

