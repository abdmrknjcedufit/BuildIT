namespace BuildIT.Model.Requests
{
    public class ComplaintInsertRequest
    {
        public int UserId { get; set; }
        public int? OrderId { get; set; }
        public string TargetType { get; set; } = null!;
        public string Subject { get; set; } = null!;
        public string Description { get; set; } = null!;
        public string Status { get; set; } = "Open";
        public string Priority { get; set; } = "Medium";
        public string? Attachment { get; set; }
        public DateTime? ResolvedAt { get; set; }
    }
}
