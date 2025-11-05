namespace BuildIT.Services.Database;

public partial class Item
{
    public int Id { get; set; }
    public string Title { get; set; } = null!;
    public string Description { get; set; } = null!;
    public decimal Price { get; set; }
    public string ItemType { get; set; } = null!;
    public string Status { get; set; } = "Available";
    public string Condition { get; set; } = null!;
    public int? CompanyId { get; set; }
    public int? CategoryId { get; set; }
    public int? MinRentalPeriod { get; set; }
    public int? MaxRentalPeriod { get; set; }
    public string? Brand { get; set; }
    public string? Model { get; set; }
    public int? Year { get; set; }
    public DateTime? AvailabilityDate { get; set; }
    public int TotalPurchases { get; set; } = 0;
    public int TotalRentals { get; set; } = 0;
    public int TotalOrders { get; set; } = 0;
    public DateTime? LastSoldDate { get; set; }
    public DateTime? LastRentedDate { get; set; }
    public bool IsAvailable { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public virtual Company? Company { get; set; }
    public virtual Category? Category { get; set; }
}

