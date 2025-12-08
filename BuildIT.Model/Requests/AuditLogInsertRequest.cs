namespace BuildIT.Model.Requests
{
    public class AuditLogInsertRequest
    {
        public int? UserId { get; set; }
        public string? Username { get; set; }
        public string Action { get; set; } = null!;
        public string? EntityId { get; set; }
        public string? RequestData { get; set; }
        public string ResponseStatus { get; set; } = null!;
        public string? Message { get; set; }
    }
}

