namespace BuildIT.Model.Requests;

public class VerifyTwoFactorRequest
{
    public string Username { get; set; } = null!;
    public string Code { get; set; } = null!;
}

