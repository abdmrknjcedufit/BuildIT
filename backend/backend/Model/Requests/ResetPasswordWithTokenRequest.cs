namespace BuildIT.Model.Requests;

public class ResetPasswordWithTokenRequest
{
    public string Token { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
}

