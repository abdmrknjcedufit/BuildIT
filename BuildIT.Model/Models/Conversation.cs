namespace BuildIT.Model.Models;

public class Conversation
{
    public int Id { get; set; }
    public int User1Id { get; set; }
    public int User2Id { get; set; }
    public int? ListingId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public User? User1 { get; set; }
    public User? User2 { get; set; }
    public Listing? Listing { get; set; }
    public List<Message>? Messages { get; set; }
    public int UnreadCount { get; set; }
    public Message? LastMessage { get; set; }
}

