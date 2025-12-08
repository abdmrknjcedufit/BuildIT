namespace BuildIT.Services.Database;

public partial class Listing
{
    public int Id { get; set; }
    public int ItemId { get; set; }
    public int UserId { get; set; }
    public string Title { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string ListingType { get; set; } = null!;
    public string Status { get; set; } = "Active";
    public int? CityId { get; set; }
    public bool IsFeatured { get; set; } = false;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? Images { get; set; }
    public int? MinRentalDays { get; set; }
    public int? MaxRentalDays { get; set; }

    public virtual Item Item { get; set; } = null!;
    public virtual User User { get; set; } = null!;
    public virtual City? City { get; set; }
}

