namespace BuildIT.Services.Database;

public partial class Conversation
{
    public int Id { get; set; }
    public int User1Id { get; set; }
    public int User2Id { get; set; }
    public int? ListingId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public virtual User User1 { get; set; } = null!;
    public virtual User User2 { get; set; } = null!;
    public virtual Listing? Listing { get; set; }
    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();
}

