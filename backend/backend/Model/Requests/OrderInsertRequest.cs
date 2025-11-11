namespace BuildIT.Model.Requests
{
    public class OrderInsertRequest
    {
        public int UserId { get; set; }
        public string OrderNumber { get; set; } = null!;
        public string Status { get; set; } = "Pending";
        public string OrderType { get; set; } = "Purchase";
        public decimal TotalAmount { get; set; }
        public decimal? DiscountAmount { get; set; }
        public decimal? TaxAmount { get; set; }
        public decimal FinalAmount { get; set; }
        public string PaymentMethod { get; set; } = null!;
        public string PaymentStatus { get; set; } = "Pending";
        public int? TransactionId { get; set; }
        public string? ShippingAddress { get; set; }
        public string? BillingAddress { get; set; }
        public DateTime? ExpectedDeliveryDate { get; set; }
        public bool IsInvoiceGenerated { get; set; } = false;
        public string Priority { get; set; } = "Normal";
    }
}
