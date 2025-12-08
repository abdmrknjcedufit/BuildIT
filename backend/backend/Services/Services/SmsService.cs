using BuildIT.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Twilio;
using Twilio.Rest.Api.V2010.Account;

namespace BuildIT.Services.Services;

public class SmsService : ISmsService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<SmsService> _logger;

    public SmsService(IConfiguration configuration, ILogger<SmsService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendTwoFactorCodeSmsAsync(string phoneNumber, string code)
    {
        try
        {
            var smsProvider = _configuration["SMS:Provider"] ?? "Console";
            
            if (smsProvider == "Console")
            {
                _logger.LogInformation($"2FA Code for {phoneNumber}: {code}");
                return;
            }

            var apiKey = _configuration["SMS:ApiKey"];
            var apiSecret = _configuration["SMS:ApiSecret"];
            var fromNumber = _configuration["SMS:FromNumber"];

            var message = $"Vaš kod za BuildIT dvofaktorsku autentifikaciju je: {code}. Kod je validan 10 minuta.";

            if (smsProvider == "Twilio")
            {
                await SendViaTwilioAsync(phoneNumber, message, apiKey, apiSecret, fromNumber);
            }
            else
            {
                _logger.LogWarning($"Unknown SMS provider: {smsProvider}. Using console logging.");
                _logger.LogInformation($"2FA Code for {phoneNumber}: {code}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending 2FA SMS to {phoneNumber}");
            throw;
        }
    }

    public async Task SendPasswordResetSmsAsync(string phoneNumber, string newPassword)
    {
        try
        {
            var smsProvider = _configuration["SMS:Provider"] ?? "Console";
            
            var message = $"BuildIT - Vaša nova lozinka je: {newPassword}";

            if (smsProvider == "Console")
            {
                _logger.LogInformation($"🔵 SMS Password Reset for {phoneNumber}:");
                _logger.LogInformation($"🔵 New Password: {newPassword}");
                await Task.CompletedTask;
                return;
            }

            var apiKey = _configuration["SMS:ApiKey"];
            var apiSecret = _configuration["SMS:ApiSecret"];
            var fromNumber = _configuration["SMS:FromNumber"];

            if (smsProvider == "Twilio")
            {
                await SendViaTwilioAsync(phoneNumber, message, apiKey, apiSecret, fromNumber);
            }
            else
            {
                _logger.LogWarning($"Unknown SMS provider: {smsProvider}. Using console logging.");
                _logger.LogInformation($"🔵 SMS Password Reset for {phoneNumber}:");
                _logger.LogInformation($"🔵 New Password: {newPassword}");
                await Task.CompletedTask;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending password reset SMS to {phoneNumber}");
            throw;
        }
    }

    private async Task SendViaTwilioAsync(string phoneNumber, string message, string? accountSid, string? authToken, string? fromNumber)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(accountSid) || string.IsNullOrWhiteSpace(authToken) || string.IsNullOrWhiteSpace(fromNumber))
            {
                _logger.LogWarning("Twilio credentials not configured. Using console logging.");
                _logger.LogInformation($"SMS for {phoneNumber}: {message}");
                await Task.CompletedTask;
                return;
            }

            TwilioClient.Init(accountSid, authToken);

            var twilioMessage = await MessageResource.CreateAsync(
                body: message,
                from: new Twilio.Types.PhoneNumber(fromNumber),
                to: new Twilio.Types.PhoneNumber(phoneNumber)
            );

            _logger.LogInformation($"SMS sent successfully to {phoneNumber}. Message SID: {twilioMessage.Sid}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending SMS via Twilio to {phoneNumber}");
            _logger.LogWarning("Falling back to console logging.");
            _logger.LogInformation($"SMS for {phoneNumber}: {message}");
            throw;
        }
    }
}

