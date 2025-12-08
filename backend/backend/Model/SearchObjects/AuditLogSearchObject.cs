namespace BuildIT.Model.SearchObjects
{
    public class AuditLogSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? Username { get; set; }
        public string? Action { get; set; }
        public string? ResponseStatus { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}
