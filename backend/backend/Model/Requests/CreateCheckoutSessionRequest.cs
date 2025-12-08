namespace BuildIT.Model.Requests;

public class CreateCheckoutSessionRequest
{
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    public string? SuccessUrl { get; set; }
    public string? CancelUrl { get; set; }
    public int UserId { get; set; }
    public List<int> CartIds { get; set; } = new();
    public int? DeliveryProviderId { get; set; }
    public string? DeliveryType { get; set; }
    public string? ShippingAddress { get; set; }
}

