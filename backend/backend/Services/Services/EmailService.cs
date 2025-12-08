using BuildIT.Services.Interfaces;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Configuration;

namespace BuildIT.Services.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public async Task SendPasswordResetEmailAsync(string toEmail, string resetToken, string resetLink)
    {
        try
        {
            var smtpHost = _configuration["Email:SmtpHost"];
            var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
            var smtpUsername = _configuration["Email:SmtpUsername"];
            var smtpPassword = _configuration["Email:SmtpPassword"] ?? "";
            var useSsl = bool.Parse(_configuration["Email:UseSsl"] ?? "true");
            var fromEmail = _configuration["Email:FromEmail"] ?? "noreply@buildit.com";
            var fromName = _configuration["Email:FromName"] ?? "BuildIT";

            _logger.LogInformation($"🔵 Email Service: Sending from {fromEmail} to {toEmail}");
            
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(fromName, fromEmail));
            message.To.Add(new MailboxAddress("", toEmail));
            message.ReplyTo.Add(new MailboxAddress(fromName, fromEmail));
            message.Subject = "Reset lozinke - BuildIT";

            var bodyBuilder = new BodyBuilder();
            bodyBuilder.HtmlBody = $@"
                <html>
                <body style='font-family: Arial, sans-serif;'>
                    <h2>Reset lozinke</h2>
                    <p>Poštovani,</p>
                    <p>Primili ste zahtjev za resetovanje lozinke. Kliknite na link ispod da resetujete lozinku:</p>
                    <p><a href='{resetLink}' style='background-color: #FF6600; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;'>Resetuj lozinku</a></p>
                    <p>Ili kopirajte ovaj link u vaš browser:</p>
                    <p>{resetLink}</p>
                    <p>Ovaj link je validan 1 sat.</p>
                    <p>Ako niste zatražili reset lozinke, ignorišite ovaj email.</p>
                    <br/>
                    <p>Srdačan pozdrav,<br/>BuildIT tim</p>
                </body>
                </html>";

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            
            SecureSocketOptions socketOptions;
            if (smtpPort == 465)
            {
                socketOptions = SecureSocketOptions.SslOnConnect;
            }
            else if (smtpPort == 587)
            {
                socketOptions = SecureSocketOptions.StartTls;
            }
            else
            {
                socketOptions = useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
            }
            
            await client.ConnectAsync(smtpHost, smtpPort, socketOptions);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(message);
            await client.DisconnectAsync(true);

            _logger.LogInformation($"Password reset email sent to {toEmail}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending password reset email to {toEmail}");
            throw;
        }
    }

    public async Task SendTwoFactorCodeEmailAsync(string toEmail, string code)
    {
        try
        {
            var smtpHost = _configuration["Email:SmtpHost"];
            var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
            var smtpUsername = _configuration["Email:SmtpUsername"];
            var smtpPassword = _configuration["Email:SmtpPassword"] ?? "";
            var useSsl = bool.Parse(_configuration["Email:UseSsl"] ?? "true");
            var fromEmail = _configuration["Email:FromEmail"] ?? "noreply@buildit.com";
            var fromName = _configuration["Email:FromName"] ?? "BuildIT";

            _logger.LogInformation($"🔵 Email Service: Sending 2FA from {fromEmail} to {toEmail}");
            
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(fromName, fromEmail));
            message.To.Add(new MailboxAddress("", toEmail));
            message.ReplyTo.Add(new MailboxAddress(fromName, fromEmail));
            message.Subject = "Kod za dvofaktorsku autentifikaciju - BuildIT";

            var bodyBuilder = new BodyBuilder();
            bodyBuilder.HtmlBody = $@"
                <html>
                <body style='font-family: Arial, sans-serif;'>
                    <h2>Kod za dvofaktorsku autentifikaciju</h2>
                    <p>Poštovani,</p>
                    <p>Vaš kod za dvofaktorsku autentifikaciju je:</p>
                    <h1 style='color: #FF6600; font-size: 32px; letter-spacing: 5px;'>{code}</h1>
                    <p>Ovaj kod je validan 10 minuta.</p>
                    <p>Ne dijelite ovaj kod sa nikim.</p>
                    <br/>
                    <p>Srdačan pozdrav,<br/>BuildIT tim</p>
                </body>
                </html>";

            message.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            
            SecureSocketOptions socketOptions;
            if (smtpPort == 465)
            {
                socketOptions = SecureSocketOptions.SslOnConnect;
            }
            else if (smtpPort == 587)
            {
                socketOptions = SecureSocketOptions.StartTls;
            }
            else
            {
                socketOptions = useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
            }
            
            await client.ConnectAsync(smtpHost, smtpPort, socketOptions);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(message);
            await client.DisconnectAsync(true);

            _logger.LogInformation($"2FA code email sent to {toEmail}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error sending 2FA code email to {toEmail}");
            throw;
        }
    }
}

