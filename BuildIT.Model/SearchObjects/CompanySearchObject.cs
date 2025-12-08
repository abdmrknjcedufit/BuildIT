namespace BuildIT.Model.SearchObjects
{
    public class CompanySearchObject : BaseSearchObject
    {
        public string? FTS { get; set; }
        public bool? IsActive { get; set; }
        public int? UserId { get; set; }
    }
}

