namespace BuildIT.Model.Requests
{
    public class CompanyUpdateRequest
    {
        public string? Name { get; set; }
        public string? PIB { get; set; }
        public string? Address { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public string? Logo { get; set; }
        public string? Description { get; set; }
        public bool? IsActive { get; set; }
        public int? CityId { get; set; }
    }
}

