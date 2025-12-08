namespace BuildIT.Model.Requests;

public class DeliveryProviderInsertRequest
{
    public string Name { get; set; } = null!;
    public string Code { get; set; } = null!;
    public decimal? Price { get; set; }
    public bool IsActive { get; set; } = true;
}

