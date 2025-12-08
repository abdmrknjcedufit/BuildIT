using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Data;
using Microsoft.Data.SqlClient;

namespace BuildIT.Subscriber;

public class OrderNotificationWorker : BackgroundService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<OrderNotificationWorker> _logger;
    private IConnection? _connection;
    private IModel? _channel;
    private readonly string _queueName = "order_notifications";

    public OrderNotificationWorker(IConfiguration configuration, ILogger<OrderNotificationWorker> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);

        var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
        var port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672");
        var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
        var password = _configuration["RabbitMQ:Password"] ?? "guest";
        var queueName = _configuration["RabbitMQ:QueueName"] ?? _queueName;

        _logger.LogInformation($"🔵 OrderNotificationWorker: Povezivanje na RabbitMQ - Host: {hostName}, Port: {port}, Queue: {queueName}");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (_connection == null || !_connection.IsOpen)
                {
                    var factory = new ConnectionFactory
                    {
                        HostName = hostName,
                        Port = port,
                        UserName = userName,
                        Password = password
                    };

                    try
                    {
                        _connection = factory.CreateConnection();
                        _channel = _connection.CreateModel();

                        _channel.QueueDeclare(
                            queue: queueName,
                            durable: true,
                            exclusive: false,
                            autoDelete: false,
                            arguments: null
                        );

                        _channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

                        _logger.LogInformation($"✅ RabbitMQ: Konekcija uspostavljena. Queue: {queueName}");

                        var consumer = new EventingBasicConsumer(_channel);
                        var channelRef = _channel; // Capture channel reference
                        consumer.Received += async (model, ea) =>
                        {
                            var body = ea.Body.ToArray();
                            var message = Encoding.UTF8.GetString(body);
                            var deliveryTag = ea.DeliveryTag;

                            try
                            {
                                _logger.LogInformation($"📨 Primljena poruka: {message}");

                                var orderNotification = JsonSerializer.Deserialize<OrderNotification>(message);

                                if (orderNotification != null && channelRef != null && !channelRef.IsClosed)
                                {
                                    var emailSent = await SendOrderNotificationEmail(orderNotification);

                                    if (emailSent)
                                    {
                                        _logger.LogInformation($"✅ Poruka obrađena uspješno za OrderId={orderNotification.OrderId}");
                                        channelRef.BasicAck(deliveryTag: deliveryTag, multiple: false);
                                    }
                                    else
                                    {
                                        _logger.LogError($"❌ Greška pri slanju email-a. Poruka će biti vraćena u queue.");
                                        channelRef.BasicNack(deliveryTag: deliveryTag, multiple: false, requeue: true);
                                    }
                                }
                                else
                                {
                                    if (orderNotification == null)
                                    {
                                        _logger.LogWarning($"⚠️ Neuspješno deserijalizovanje poruke");
                                    }
                                    if (channelRef != null && !channelRef.IsClosed)
                                    {
                                        channelRef.BasicNack(deliveryTag: deliveryTag, multiple: false, requeue: true);
                                    }
                                }
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, $"❌ Greška pri obradi poruke: {ex.Message}");
                                if (channelRef != null && !channelRef.IsClosed)
                                {
                                    try
                                    {
                                        channelRef.BasicNack(deliveryTag: deliveryTag, multiple: false, requeue: true);
                                    }
                                    catch (Exception ackEx)
                                    {
                                        _logger.LogError(ackEx, $"❌ Greška pri Nack: {ackEx.Message}");
                                    }
                                }
                            }
                        };

                        if (_channel != null)
                        {
                            _channel.BasicConsume(
                                queue: queueName,
                                autoAck: false,
                                consumer: consumer
                            );
                        }

                        _logger.LogInformation("✅ OrderNotificationWorker: Consumer pokrenut! Servis radi i čeka poruke...");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"❌ Greška pri povezivanju na RabbitMQ: {ex.Message}");
                        _connection?.Close();
                        _connection?.Dispose();
                        _channel?.Close();
                        _channel?.Dispose();
                        _connection = null;
                        _channel = null;
                        await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
                        continue;
                    }
                }

                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ Neočekivana greška u OrderNotificationWorker: {ex.Message}");
                await Task.Delay(TimeSpan.FromSeconds(30), stoppingToken);
            }
        }
    }

    private async Task<bool> SendOrderNotificationEmail(OrderNotification notification)
    {
        try
        {
            var connectionString = _configuration["ConnectionStrings:BuildITDB"];
            if (string.IsNullOrEmpty(connectionString))
            {
                _logger.LogError("❌ Connection string nije pronađen");
                return false;
            }

            var sellerEmail = await GetSellerEmail(notification.SellerId, connectionString);
            if (string.IsNullOrEmpty(sellerEmail))
            {
                _logger.LogWarning($"⚠️ Email prodavca nije pronađen za SellerId={notification.SellerId}");
                return false;
            }

            var smtpHost = _configuration["Email:SmtpHost"];
            var smtpPort = int.Parse(_configuration["Email:SmtpPort"] ?? "587");
            var smtpUsername = _configuration["Email:SmtpUsername"];
            var smtpPassword = _configuration["Email:SmtpPassword"];
            var useSsl = bool.Parse(_configuration["Email:UseSsl"] ?? "false");
            var fromEmail = _configuration["Email:FromEmail"];
            var fromName = _configuration["Email:FromName"];

            var emailMessage = new MimeMessage();
            emailMessage.From.Add(new MailboxAddress(fromName, fromEmail));
            emailMessage.To.Add(new MailboxAddress("", sellerEmail));
            emailMessage.Subject = $"Nova narudžba - {notification.OrderNumber}";

            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                <html>
                <body style='font-family: Arial, sans-serif;'>
                    <h2 style='color: #FF6B35;'>Nova narudžba!</h2>
                    <p>Poštovani,</p>
                    <p>Imate novu narudžbu na BuildIT platformi.</p>
                    <div style='background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;'>
                        <p><strong>Broj narudžbe:</strong> {notification.OrderNumber}</p>
                        <p><strong>Iznos:</strong> {notification.Amount:F2} KM</p>
                        <p><strong>Datum:</strong> {notification.Timestamp:dd.MM.yyyy HH:mm}</p>
                    </div>
                    <p>Molimo vas da provjerite detalje narudžbe u vašem profilu.</p>
                    <p>Srdačan pozdrav,<br>BuildIT tim</p>
                </body>
                </html>"
            };

            emailMessage.Body = bodyBuilder.ToMessageBody();

            using var client = new SmtpClient();
            var secureOptions = smtpPort == 587 ? SecureSocketOptions.StartTls : (useSsl ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.None);
            await client.ConnectAsync(smtpHost, smtpPort, secureOptions);
            await client.AuthenticateAsync(smtpUsername, smtpPassword);
            await client.SendAsync(emailMessage);
            await client.DisconnectAsync(true);

            _logger.LogInformation($"✅ Email poslan prodavcu (SellerId={notification.SellerId}, Email={sellerEmail})");
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Greška pri slanju email-a prodavcu (SellerId={notification.SellerId})");
            return false;
        }
    }

    private async Task<string?> GetSellerEmail(int sellerId, string connectionString)
    {
        try
        {
            using var connection = new SqlConnection(connectionString);
            await connection.OpenAsync();

            var command = new SqlCommand(
                "SELECT Email FROM [Users] WHERE Id = @SellerId",
                connection
            );
            command.Parameters.AddWithValue("@SellerId", sellerId);

            var result = await command.ExecuteScalarAsync();
            return result?.ToString();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"❌ Greška pri dohvatanju email-a prodavca (SellerId={sellerId})");
            return null;
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

