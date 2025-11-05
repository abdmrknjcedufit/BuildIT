namespace BuildIT.Model.Requests
{
    public class UserInsertRequest
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string? Phone { get; set; }
        public string Password { get; set; } = null!;
        public string PasswordConfirm { get; set; } = null!;
        public DateOnly BirthDate { get; set; }
        public string UserType { get; set; } = "Individual";
        public string Role { get; set; } = "User";
    }
}

