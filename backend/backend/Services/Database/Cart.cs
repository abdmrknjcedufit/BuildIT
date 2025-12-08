namespace BuildIT.Services.Database;

public partial class Cart
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int ListingId { get; set; }
    public int Quantity { get; set; } = 1;
    public int? RentalDays { get; set; }
    public decimal? PricePerDay { get; set; }
    public decimal TotalPrice { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public virtual User User { get; set; } = null!;
    public virtual Listing Listing { get; set; } = null!;
}

