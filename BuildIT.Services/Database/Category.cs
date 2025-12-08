namespace BuildIT.Services.Database;

public partial class Category
{
    public int Id { get; set; }
    public string Description { get; set; } = null!;

    public virtual ICollection<Subcategory> Subcategories { get; set; } = new List<Subcategory>();
    public virtual ICollection<Item> Items { get; set; } = new List<Item>();
}

