namespace BuildIT.Services.Database;

public partial class Notification
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string NotificationType { get; set; } = null!;
    public int? ReferenceId { get; set; }
    public bool IsRead { get; set; } = false;
    public bool IsSent { get; set; } = false;
    public DateTime? SentAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Priority { get; set; } = "Normal";

    public virtual User User { get; set; } = null!;
}
