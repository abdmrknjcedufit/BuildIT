namespace BuildIT.Model.Requests;

public class TwoFactorRequest
{
    public string Username { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string? TwoFactorMethod { get; set; }
}

