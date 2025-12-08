namespace BuildIT.Model.Models
{
    public class Order
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string OrderNumber { get; set; } = null!;
        public string Status { get; set; } = null!;
        public string OrderType { get; set; } = null!;
        public decimal TotalAmount { get; set; }
        public decimal? DiscountAmount { get; set; }
        public decimal? TaxAmount { get; set; }
        public decimal FinalAmount { get; set; }
        public string PaymentMethod { get; set; } = null!;
        public string PaymentStatus { get; set; } = null!;
        public int? TransactionId { get; set; }
        public string? ShippingAddress { get; set; }
        public string? BillingAddress { get; set; }
        public DateTime? ExpectedDeliveryDate { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public bool IsInvoiceGenerated { get; set; }
        public string Priority { get; set; } = null!;
        public int? DeliveryProviderId { get; set; }
        public string? DeliveryType { get; set; }
        public int? RentalDays { get; set; }
        public DateTime? RentalStartDate { get; set; }
        public DateTime? RentalEndDate { get; set; }
        public User? User { get; set; }
        public Transaction? Transaction { get; set; }
        public DeliveryProvider? DeliveryProvider { get; set; }
    }
}

