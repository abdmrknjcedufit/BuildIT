namespace BuildIT.Model.Requests;

public class CartInsertRequest
{
    public int UserId { get; set; }
    public int ListingId { get; set; }
    public int Quantity { get; set; } = 1;
    public int? RentalDays { get; set; }
}

