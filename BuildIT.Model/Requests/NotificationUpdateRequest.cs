namespace BuildIT.Model.Requests
{
    public class NotificationUpdateRequest
    {
        public string? Title { get; set; }
        public string? Message { get; set; }
        public string? NotificationType { get; set; }
        public int? ReferenceId { get; set; }
        public bool? IsRead { get; set; }
        public bool? IsSent { get; set; }
        public DateTime? SentAt { get; set; }
        public string? Priority { get; set; }
    }
}

