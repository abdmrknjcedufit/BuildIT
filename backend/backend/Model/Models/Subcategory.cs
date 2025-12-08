namespace BuildIT.Model.Models
{
    public class Subcategory
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string Description { get; set; } = null!;
    }
}

