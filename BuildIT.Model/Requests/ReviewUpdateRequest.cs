namespace BuildIT.Model.Requests
{
    public class ReviewUpdateRequest
    {
        public int? Rating { get; set; }
        public string? Comment { get; set; }
        public bool? IsApproved { get; set; }
        public int? HelpfulCount { get; set; }
        public int? NotHelpfulCount { get; set; }
    }
}

