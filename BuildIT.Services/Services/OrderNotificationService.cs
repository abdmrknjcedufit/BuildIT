using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using BuildIT.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class OrderNotificationService : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<OrderNotificationService> _logger;
        private readonly IServiceProvider _serviceProvider;
        private IConnection? _connection;
        private IModel? _channel;
        private readonly string _queueName = "order_notifications";
        private bool _isConsumerStarted = false;

        public OrderNotificationService(IConfiguration configuration, ILogger<OrderNotificationService> logger, IServiceProvider serviceProvider)
        {
            _configuration = configuration;
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);

            var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
            var port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672");
            var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
            var password = _configuration["RabbitMQ:Password"] ?? "guest";

            _logger.LogInformation($"🔵 OrderNotificationService: Povezivanje na RabbitMQ - Host: {hostName}, Port: {port}, Queue: {_queueName}");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    if (_connection == null || !_connection.IsOpen || _channel == null || _channel.IsClosed)
                    {
                        _isConsumerStarted = false;
                        await ConnectToRabbitMQ(hostName, port, userName, password, stoppingToken);
                    }

                    if (_channel != null && !_channel.IsClosed && !_isConsumerStarted)
                    {
                        _logger.LogInformation($"🔵 OrderNotificationService: Pokretanje consumer-a...");
                        var consumer = new EventingBasicConsumer(_channel);
                        consumer.Received += async (model, ea) =>
                        {
                            var body = ea.Body.ToArray();
                            var message = Encoding.UTF8.GetString(body);
                            var deliveryTag = ea.DeliveryTag;

                            _logger.LogInformation($"📨 OrderNotificationService: Primljena poruka! DeliveryTag: {deliveryTag}");
                            _logger.LogInformation($"📨 OrderNotificationService: Sadržaj poruke: {message}");

                            try
                            {
                                var orderNotification = JsonSerializer.Deserialize<OrderNotification>(message);

                                if (orderNotification == null)
                                {
                                    _logger.LogError($"❌ OrderNotificationService: Neuspješno deserijalizovanje poruke. Poruka: {message}");
                                    _channel.BasicNack(deliveryTag, false, false);
                                    return;
                                }

                                _logger.LogInformation($"🔵 OrderNotificationService: Obrada notifikacije - SellerId: {orderNotification.SellerId}, OrderId: {orderNotification.OrderId}, OrderNumber: {orderNotification.OrderNumber}, Amount: {orderNotification.Amount}");

                                var sellerEmail = await GetSellerEmailAsync(orderNotification.SellerId);

                                if (string.IsNullOrEmpty(sellerEmail))
                                {
                                    _logger.LogWarning($"⚠️ OrderNotificationService: Email prodavca nije pronađen za SellerId: {orderNotification.SellerId}");
                                    _channel.BasicAck(deliveryTag, false);
                                    return;
                                }

                                _logger.LogInformation($"🔵 OrderNotificationService: Email prodavca pronađen: {sellerEmail}");

                                var emailSent = await SendOrderNotificationEmailAsync(
                                    sellerEmail,
                                    orderNotification.OrderNumber,
                                    orderNotification.Amount
                                );

                                if (emailSent)
                                {
                                    _logger.LogInformation($"✅ OrderNotificationService: Email uspješno poslan prodavcu! SellerId: {orderNotification.SellerId}, Email: {sellerEmail}, OrderNumber: {orderNotification.OrderNumber}");
                                    _channel.BasicAck(deliveryTag, false);
                                }
                                else
                                {
                                    _logger.LogError($"❌ OrderNotificationService: Greška pri slanju emaila. Poruka će biti vraćena u queue.");
                                    _channel.BasicNack(deliveryTag, false, true);
                                }
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"❌ OrderNotificationService: Greška pri obradi poruke. DeliveryTag: {deliveryTag}, Error: {ex.Message}");
                                _logger.LogError($"❌ OrderNotificationService: Stack trace: {ex.StackTrace}");
                                _channel.BasicNack(deliveryTag, false, true);
                            }
                        };

                        _channel.BasicConsume(
                            queue: _queueName,
                            autoAck: false,
                            consumer: consumer
                        );

                        _isConsumerStarted = true;
                        _logger.LogInformation("✅ OrderNotificationService: Consumer pokrenut! Servis radi i čeka poruke...");
                    }

                    await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"❌ OrderNotificationService: Greška u ExecuteAsync: {ex.Message}");
                    _isConsumerStarted = false;
                    await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
                }
            }
        }

        private Task ConnectToRabbitMQ(string hostName, int port, string userName, string password, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("🔵 OrderNotificationService: Kreiranje konekcije sa RabbitMQ...");

                var factory = new ConnectionFactory
                {
                    HostName = hostName,
                    Port = port,
                    UserName = userName,
                    Password = password
                };

                _connection?.Close();
                _connection?.Dispose();
                _channel?.Close();
                _channel?.Dispose();

                _connection = factory.CreateConnection();
                _channel = _connection.CreateModel();

                _logger.LogInformation($"🔵 OrderNotificationService: Deklarisanje queue-a: {_queueName}");
                _channel.QueueDeclare(
                    queue: _queueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null
                );

                _logger.LogInformation($"✅ OrderNotificationService: Konekcija uspostavljena! Queue: {_queueName}");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, $"⚠️ OrderNotificationService: Nije moguće uspostaviti konekciju sa RabbitMQ. Pokušat ću ponovo za 10 sekundi.");
            }
            
            return Task.CompletedTask;
        }

        private async Task<string?> GetSellerEmailAsync(int sellerId)
        {
            try
            {
                _logger.LogInformation($"🔵 OrderNotificationService: Povezivanje na bazu za dohvatanje emaila prodavca (SellerId/UserId: {sellerId})...");

                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<BuildITDbContext>();

                var user = await dbContext.Users
                    .Where(u => u.Id == sellerId)
                    .Select(u => new { u.Email })
                    .FirstOrDefaultAsync();

                var email = user?.Email ?? string.Empty;

                _logger.LogInformation($"🔵 OrderNotificationService: Email prodavca dohvaćen za UserId {sellerId}: {(string.IsNullOrEmpty(email) ? "N/A" : email)}");

                return string.IsNullOrEmpty(email) ? null : email;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ OrderNotificationService: Greška pri dohvatanju emaila prodavca (SellerId/UserId: {sellerId}): {ex.Message}");
                _logger.LogError($"❌ OrderNotificationService: Stack trace: {ex.StackTrace}");
                return null;
            }
        }

        private async Task<bool> SendOrderNotificationEmailAsync(string toEmail, string orderNumber, decimal amount)
        {
            try
            {
                _logger.LogInformation($"🔵 OrderNotificationService: Priprema emaila za: {toEmail}, OrderNumber: {orderNumber}, Amount: {amount}");

                var smtpHost = _configuration["Email:SmtpHost"] ?? "smtp.gmail.com";
                var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
                var smtpUsername = _configuration["Email:SmtpUsername"] ?? "";
                var smtpPassword = _configuration["Email:SmtpPassword"] ?? "";
                var useSsl = bool.Parse(_configuration["Email:UseSsl"] ?? "true");
                var fromEmail = _configuration["Email:FromEmail"] ?? "";
                var fromName = _configuration["Email:FromName"] ?? "BuildIT";

                _logger.LogInformation($"🔵 OrderNotificationService: SMTP konfiguracija - Host: {smtpHost}, Port: {smtpPort}, From: {fromEmail}");

                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(fromName, fromEmail));
                message.To.Add(new MailboxAddress("", toEmail));
                message.Subject = $"🎉 Vaš artikal je uspješno kupljen! - {orderNumber}";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
                        <html>
                        <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                            <div style='max-width: 600px; margin: 0 auto; padding: 20px; background-color: #f9f9f9;'>
                                <div style='background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0;'>
                                    <h1 style='margin: 0;'>🎉 Čestitamo!</h1>
                                </div>
                                <div style='background-color: white; padding: 30px; border-radius: 0 0 5px 5px;'>
                                    <p style='font-size: 16px;'>Vaš artikal je uspješno kupljen!</p>
                                    <div style='background-color: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0;'>
                                        <p style='margin: 5px 0;'><strong>Broj narudžbe:</strong> {orderNumber}</p>
                                        <p style='margin: 5px 0;'><strong>Iznos:</strong> {amount:C}</p>
                                        <p style='margin: 5px 0;'><strong>Datum:</strong> {DateTime.Now:dd.MM.yyyy HH:mm}</p>
                                    </div>
                                    <p style='font-size: 14px; color: #666;'>Hvala vam što koristite BuildIT platformu!</p>
                                </div>
                            </div>
                        </body>
                        </html>"
                };

                message.Body = bodyBuilder.ToMessageBody();

                _logger.LogInformation($"🔵 OrderNotificationService: Slanje emaila preko SMTP...");
                _logger.LogInformation($"🔵 OrderNotificationService: SMTP detalji - Host: {smtpHost}, Port: {smtpPort}, Username: {smtpUsername}, UseSsl: {useSsl}");
                _logger.LogInformation($"🔵 OrderNotificationService: Email detalji - From: {fromEmail}, To: {toEmail}, Subject: {message.Subject}");

                using var client = new SmtpClient();
                
                _logger.LogInformation($"🔵 OrderNotificationService: Povezivanje na SMTP server...");
                await client.ConnectAsync(smtpHost, smtpPort, useSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None);
                _logger.LogInformation($"✅ OrderNotificationService: Povezan na SMTP server!");

                _logger.LogInformation($"🔵 OrderNotificationService: Autentifikacija...");
                await client.AuthenticateAsync(smtpUsername, smtpPassword);
                _logger.LogInformation($"✅ OrderNotificationService: Autentifikacija uspješna!");

                _logger.LogInformation($"🔵 OrderNotificationService: Slanje emaila...");
                var response = await client.SendAsync(message);
                _logger.LogInformation($"✅ OrderNotificationService: Email poslan! Server response: {response}");

                _logger.LogInformation($"🔵 OrderNotificationService: Prekidanje konekcije...");
                await client.DisconnectAsync(true);
                _logger.LogInformation($"✅ OrderNotificationService: Konekcija prekinuta!");

                _logger.LogInformation($"✅ OrderNotificationService: Email uspješno poslan na: {toEmail}");
                _logger.LogInformation($"✅ OrderNotificationService: Provjeri inbox i spam folder za email: {toEmail}");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ OrderNotificationService: Greška pri slanju emaila na {toEmail}: {ex.Message}");
                _logger.LogError($"❌ OrderNotificationService: Stack trace: {ex.StackTrace}");
                return false;
            }
        }

        public override void Dispose()
        {
            _channel?.Close();
            _channel?.Dispose();
            _connection?.Close();
            _connection?.Dispose();
            base.Dispose();
        }
    }

    public class OrderNotification
    {
        public int SellerId { get; set; }
        public int OrderId { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public DateTime Timestamp { get; set; }
    }
}

