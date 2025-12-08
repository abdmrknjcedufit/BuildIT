namespace BuildIT.Model.Models
{
    public class User
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? Phone { get; set; }
        public string? Address { get; set; }
        public int? CityId { get; set; }
        public string? PostalCode { get; set; }
        public DateOnly BirthDate { get; set; }
        public string UserType { get; set; } = "Individual";
        public bool IsActive { get; set; }
        public bool TwoFactorEnabled { get; set; }
        public string? TwoFactorMethod { get; set; }
        public DateTime CreatedAt { get; set; }
        public List<string> Roles { get; set; } = new();
    }
}

