namespace BuildIT.Services.Database;

public partial class Review
{
    public int Id { get; set; }
    public int ReviewerId { get; set; }
    public string TargetType { get; set; } = null!;
    public int TargetId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public int? TransactionId { get; set; }
    public bool IsApproved { get; set; } = false;
    public int HelpfulCount { get; set; } = 0;
    public int NotHelpfulCount { get; set; } = 0;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }

    public virtual User Reviewer { get; set; } = null!;
    public virtual Transaction? Transaction { get; set; }
}
