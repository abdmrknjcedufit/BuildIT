namespace BuildIT.Services.Database;

public partial class Company
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? PIB { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? Logo { get; set; }
    public string? Description { get; set; }
    public int UserId { get; set; }
    public int? CityId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;
    public virtual City? City { get; set; }
}

