namespace BuildIT.Services.Database;

public partial class City
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public bool IsActive { get; set; } = true;

    public virtual ICollection<Company> Companies { get; set; } = new List<Company>();
}

