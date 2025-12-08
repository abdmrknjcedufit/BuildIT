namespace BuildIT.Model.Models
{
    public class Review
    {
        public int Id { get; set; }
        public int ReviewerId { get; set; }
        public string TargetType { get; set; } = null!;
        public int TargetId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public int? TransactionId { get; set; }
        public bool IsApproved { get; set; }
        public int HelpfulCount { get; set; }
        public int NotHelpfulCount { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}

