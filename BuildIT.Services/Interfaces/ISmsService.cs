namespace BuildIT.Services.Interfaces;

public interface ISmsService
{
    Task SendTwoFactorCodeSmsAsync(string phoneNumber, string code);
    Task SendPasswordResetSmsAsync(string phoneNumber, string newPassword);
}

