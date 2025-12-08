namespace BuildIT.Model.Requests;

public class CartUpdateRequest
{
    public int Quantity { get; set; }
    public int? RentalDays { get; set; }
}

