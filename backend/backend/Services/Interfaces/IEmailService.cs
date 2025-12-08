namespace BuildIT.Services.Interfaces;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(string toEmail, string resetToken, string resetLink);
    Task SendTwoFactorCodeEmailAsync(string toEmail, string code);
}

