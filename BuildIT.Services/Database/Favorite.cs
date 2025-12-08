namespace BuildIT.Services.Database
{
    public partial class Favorite
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ListingId { get; set; }
        public DateTime CreatedAt { get; set; }

        public virtual User User { get; set; } = null!;
        public virtual Listing Listing { get; set; } = null!;
    }
}

