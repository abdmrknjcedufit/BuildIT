namespace BuildIT.Model.Requests
{
    public class SubcategoryInsertRequest
    {
        public int CategoryId { get; set; }
        public string Description { get; set; } = null!;
    }
}

