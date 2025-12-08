using Microsoft.AspNetCore.Mvc;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestEmailController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TestEmailController> _logger;

        public TestEmailController(IConfiguration configuration, ILogger<TestEmailController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        [HttpPost("send-test-email")]
        public async Task<IActionResult> SendTestEmail([FromBody] TestEmailRequest request)
        {
            try
            {
                _logger.LogInformation($"🔵 TEST-EMAIL: Počinje slanje test emaila na: {request.ToEmail}");

                var smtpHost = _configuration["Email:SmtpHost"] ?? "smtp.gmail.com";
                var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
                var smtpUsername = _configuration["Email:SmtpUsername"] ?? "";
                var smtpPassword = _configuration["Email:SmtpPassword"] ?? "";
                var useSsl = bool.Parse(_configuration["Email:UseSsl"] ?? "true");
                var fromEmail = _configuration["Email:FromEmail"] ?? "";
                var fromName = _configuration["Email:FromName"] ?? "BuildIT";

                _logger.LogInformation($"🔵 TEST-EMAIL: SMTP konfiguracija - Host: {smtpHost}, Port: {smtpPort}, From: {fromEmail}");
                _logger.LogInformation($"🔵 TEST-EMAIL: Username: {smtpUsername}, Password length: {smtpPassword?.Length ?? 0}");

                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(fromName, fromEmail));
                message.To.Add(new MailboxAddress("", request.ToEmail));
                message.Subject = "🧪 Test Email - BuildIT";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
                        <html>
                        <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                            <div style='max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;'>
                                <div style='background-color: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0;'>
                                    <h1 style='margin: 0;'>🧪 Test Email</h1>
                                </div>
                                <div style='background-color: white; padding: 30px; border-radius: 0 0 5px 5px;'>
                                    <p style='font-size: 16px;'>Ovo je test email iz BuildIT aplikacije!</p>
                                    <div style='background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0;'>
                                        <p style='margin: 5px 0;'><strong>Vrijeme slanja:</strong> {DateTime.Now:dd.MM.yyyy HH:mm:ss}</p>
                                        <p style='margin: 5px 0;'><strong>SMTP Host:</strong> {smtpHost}</p>
                                        <p style='margin: 5px 0;'><strong>SMTP Port:</strong> {smtpPort}</p>
                                        <p style='margin: 5px 0;'><strong>From Email:</strong> {fromEmail}</p>
                                    </div>
                                    <p style='font-size: 14px; color: #666;'>Ako vidite ovaj email, email sistem radi ispravno!</p>
                                </div>
                            </div>
                        </body>
                        </html>"
                };

                message.Body = bodyBuilder.ToMessageBody();

                _logger.LogInformation($"🔵 TEST-EMAIL: Povezivanje na SMTP server...");
                using var client = new SmtpClient();
                
                await client.ConnectAsync(smtpHost, smtpPort, useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);
                _logger.LogInformation($"✅ TEST-EMAIL: Povezan na SMTP server!");

                _logger.LogInformation($"🔵 TEST-EMAIL: Autentifikacija...");
                await client.AuthenticateAsync(smtpUsername, smtpPassword);
                _logger.LogInformation($"✅ TEST-EMAIL: Autentifikacija uspješna!");

                _logger.LogInformation($"🔵 TEST-EMAIL: Slanje emaila...");
                var response = await client.SendAsync(message);
                _logger.LogInformation($"✅ TEST-EMAIL: Email poslan! Server response: {response}");

                await client.DisconnectAsync(true);
                _logger.LogInformation($"✅ TEST-EMAIL: Konekcija prekinuta!");

                return Ok(new { 
                    success = true, 
                    message = $"Test email uspješno poslan na {request.ToEmail}. Provjeri inbox i spam folder.",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ TEST-EMAIL: Greška pri slanju test emaila: {ex.Message}");
                _logger.LogError($"❌ TEST-EMAIL: Stack trace: {ex.StackTrace}");
                
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ TEST-EMAIL: Inner exception: {ex.InnerException.Message}");
                }

                return BadRequest(new { 
                    success = false, 
                    message = $"Greška pri slanju test emaila: {ex.Message}",
                    details = ex.ToString()
                });
            }
        }
    }

    public class TestEmailRequest
    {
        public string ToEmail { get; set; } = string.Empty;
    }
}

