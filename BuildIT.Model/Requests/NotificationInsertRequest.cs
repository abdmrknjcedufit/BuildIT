namespace BuildIT.Model.Requests
{
    public class NotificationInsertRequest
    {
        public int UserId { get; set; }
        public string Title { get; set; } = null!;
        public string Message { get; set; } = null!;
        public string NotificationType { get; set; } = null!;
        public int? ReferenceId { get; set; }
        public bool IsRead { get; set; } = false;
        public bool IsSent { get; set; } = false;
        public DateTime? SentAt { get; set; }
        public string Priority { get; set; } = "Normal";
    }
}

