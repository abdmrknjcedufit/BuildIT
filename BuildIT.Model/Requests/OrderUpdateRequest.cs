namespace BuildIT.Model.Requests
{
    public class OrderUpdateRequest
    {
        public string? Status { get; set; }
        public string? OrderType { get; set; }
        public decimal? TotalAmount { get; set; }
        public decimal? DiscountAmount { get; set; }
        public decimal? TaxAmount { get; set; }
        public decimal? FinalAmount { get; set; }
        public string? PaymentMethod { get; set; }
        public string? PaymentStatus { get; set; }
        public int? TransactionId { get; set; }
        public string? ShippingAddress { get; set; }
        public string? BillingAddress { get; set; }
        public DateTime? ExpectedDeliveryDate { get; set; }
        public bool? IsInvoiceGenerated { get; set; }
        public string? Priority { get; set; }
    }
}

