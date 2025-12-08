namespace BuildIT.Model.SearchObjects
{
    public class ReviewSearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? ReviewerId { get; set; }
        public string? TargetType { get; set; }
        public int? TargetId { get; set; }
        public int? TransactionId { get; set; }
        public int? MinRating { get; set; }
        public int? MaxRating { get; set; }
        public bool? IsApproved { get; set; }
    }
}

