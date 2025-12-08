namespace BuildIT.Model.Requests
{
    public class ReviewInsertRequest
    {
        public int ReviewerId { get; set; }
        public string TargetType { get; set; } = null!;
        public int TargetId { get; set; }
        public int Rating { get; set; }
        public string? Comment { get; set; }
        public int? TransactionId { get; set; }
        public bool IsApproved { get; set; } = false;
    }
}
