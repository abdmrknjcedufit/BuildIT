namespace BuildIT.Model.Requests;

public class DeliveryProviderUpdateRequest
{
    public string? Name { get; set; }
    public string? Code { get; set; }
    public decimal? Price { get; set; }
    public bool? IsActive { get; set; }
}

