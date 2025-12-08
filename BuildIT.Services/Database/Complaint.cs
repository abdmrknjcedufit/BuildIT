namespace BuildIT.Services.Database;

public partial class Complaint
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int? OrderId { get; set; }
    public string TargetType { get; set; } = null!;
    public string Subject { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string Status { get; set; } = "Open";
    public string Priority { get; set; } = "Medium";
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? Attachment { get; set; }
    public DateTime? ResolvedAt { get; set; }

    public virtual User User { get; set; } = null!;
    public virtual Order? Order { get; set; }
}

