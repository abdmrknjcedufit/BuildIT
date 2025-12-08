namespace BuildIT.Model.Models
{
    public class Favorite
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ListingId { get; set; }
        public DateTime CreatedAt { get; set; }
        public Listing? Listing { get; set; }
    }
}

