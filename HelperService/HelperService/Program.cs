using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;
using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using System.Data;
using Microsoft.Data.SqlClient;

var builder = Host.CreateApplicationBuilder(args);

builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true);

builder.Services.AddLogging(configure => configure.AddConsole());

var host = builder.Build();
var logger = host.Services.GetRequiredService<ILogger<Program>>();
var configuration = host.Services.GetRequiredService<IConfiguration>();

logger.LogInformation("🚀 HelperService pokrenut");

var hostName = configuration["RabbitMQ:HostName"] ?? "localhost";
var port = int.Parse(configuration["RabbitMQ:Port"] ?? "5672");
var userName = configuration["RabbitMQ:UserName"] ?? "guest";
var password = configuration["RabbitMQ:Password"] ?? "guest";
var queueName = configuration["RabbitMQ:QueueName"] ?? "order_notifications";

var factory = new ConnectionFactory
{
    HostName = hostName,
    Port = port,
    UserName = userName,
    Password = password
};

try
{
    using var connection = factory.CreateConnection();
    using var channel = connection.CreateModel();

    channel.QueueDeclare(
        queue: queueName,
        durable: true,
        exclusive: false,
        autoDelete: false,
        arguments: null
    );

    channel.BasicQos(prefetchSize: 0, prefetchCount: 1, global: false);

    logger.LogInformation($"✅ RabbitMQ: Konekcija uspostavljena. Queue: {queueName}");
    logger.LogInformation("🔵 Čekam poruke...");

    var consumer = new EventingBasicConsumer(channel);
    consumer.Received += async (model, ea) =>
    {
        var body = ea.Body.ToArray();
        var message = Encoding.UTF8.GetString(body);
        
        try
        {
            logger.LogInformation($"📨 Primljena poruka: {message}");

            var orderNotification = JsonSerializer.Deserialize<OrderNotification>(message);
            
            if (orderNotification != null)
            {
                await SendOrderNotificationEmail(orderNotification, configuration, logger);
                channel.BasicAck(deliveryTag: ea.DeliveryTag, multiple: false);
                logger.LogInformation($"✅ Poruka obrađena uspješno za OrderId={orderNotification.OrderId}");
            }
            else
            {
                logger.LogWarning($"⚠️ Neuspješno deserijalizovanje poruke");
                channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
            }
        }
        catch (Exception ex)
        {
            logger.LogError(ex, $"❌ Greška pri obradi poruke: {ex.Message}");
            channel.BasicNack(deliveryTag: ea.DeliveryTag, multiple: false, requeue: true);
        }
    };

    channel.BasicConsume(
        queue: queueName,
        autoAck: false,
        consumer: consumer
    );

    logger.LogInformation("✅ HelperService spreman za primanje poruka. Pritisnite [enter] za izlaz.");
    Console.ReadLine();
}
catch (Exception ex)
{
    logger.LogError(ex, $"❌ Fatalna greška: {ex.Message}");
    throw;
}

static async Task SendOrderNotificationEmail(OrderNotification notification, IConfiguration configuration, ILogger logger)
{
    try
    {
        var connectionString = configuration["ConnectionStrings:BuildITDB"];
        if (string.IsNullOrEmpty(connectionString))
        {
            logger.LogError("❌ Connection string nije pronađen");
            return;
        }

        var sellerEmail = await GetSellerEmail(notification.SellerId, connectionString, logger);
        if (string.IsNullOrEmpty(sellerEmail))
        {
            logger.LogWarning($"⚠️ Email prodavca nije pronađen za SellerId={notification.SellerId}");
            return;
        }

        var smtpHost = configuration["Email:SmtpHost"];
        var smtpPort = int.Parse(configuration["Email:SmtpPort"] ?? "587");
        var smtpUsername = configuration["Email:SmtpUsername"];
        var smtpPassword = configuration["Email:SmtpPassword"];
        var useSsl = bool.Parse(configuration["Email:UseSsl"] ?? "false");
        var fromEmail = configuration["Email:FromEmail"];
        var fromName = configuration["Email:FromName"];

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

        logger.LogInformation($"✅ Email poslan prodavcu (SellerId={notification.SellerId}, Email={sellerEmail})");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, $"❌ Greška pri slanju email-a prodavcu (SellerId={notification.SellerId})");
        throw;
    }
}

static async Task<string?> GetSellerEmail(int sellerId, string connectionString, ILogger logger)
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
        logger.LogError(ex, $"❌ Greška pri dohvatanju email-a prodavca (SellerId={sellerId})");
        return null;
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
