namespace BuildIT.Services.Database;

public partial class Subcategory
{
    public int Id { get; set; }
    public int CategoryId { get; set; }
    public string Description { get; set; } = null!;

    public virtual Category Category { get; set; } = null!;
}

