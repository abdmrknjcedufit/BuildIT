namespace BuildIT.Model.Requests
{
    public class ComplaintUpdateRequest
    {
        public string? Subject { get; set; }
        public string? Description { get; set; }
        public string? Status { get; set; }
        public string? Priority { get; set; }
        public string? Attachment { get; set; }
        public DateTime? ResolvedAt { get; set; }
    }
}
