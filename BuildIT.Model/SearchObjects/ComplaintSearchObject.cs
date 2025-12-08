namespace BuildIT.Model.SearchObjects
{
    public class ComplaintSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public string? Status { get; set; }
        public string? Priority { get; set; }
        public string? TargetType { get; set; }
        public DateTime? FromDate { get; set; }
        public DateTime? ToDate { get; set; }
    }
}

