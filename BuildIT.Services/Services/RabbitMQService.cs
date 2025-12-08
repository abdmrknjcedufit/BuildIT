using BuildIT.Services.Interfaces;
using RabbitMQ.Client;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace BuildIT.Services.Services
{
    public class RabbitMQService : IRabbitMQService, IDisposable
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMQService> _logger;
        private IConnection? _connection;
        private IModel? _channel;
        private readonly string _queueName = "order_notifications";

        public RabbitMQService(IConfiguration configuration, ILogger<RabbitMQService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        private bool InitializeConnection()
        {
            try
            {
                if (_connection != null && _connection.IsOpen && _channel != null && !_channel.IsClosed)
                {
                    return true;
                }

                var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
                var port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672");
                var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
                var password = _configuration["RabbitMQ:Password"] ?? "guest";

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

                _channel.QueueDeclare(
                    queue: _queueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null
                );

                _logger.LogInformation($"✅ RabbitMQ: Konekcija uspostavljena! Host: {hostName}, Port: {port}, Queue: {_queueName}");
                return true;
            }
            catch (Exception ex)
            {
                var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
                var port = _configuration["RabbitMQ:Port"] ?? "5672";
                _logger.LogError(ex, $"❌ RabbitMQ: Nije moguće uspostaviti konekciju. Host: {hostName}, Port: {port}");
                _logger.LogError($"❌ RabbitMQ: Error details: {ex.Message}");
                _logger.LogError($"❌ RabbitMQ: Stack trace: {ex.StackTrace}");
                _logger.LogWarning($"⚠️ RabbitMQ: Aplikacija će nastaviti raditi bez RabbitMQ notifikacija.");
                return false;
            }
        }

        public void PublishOrderNotification(int sellerId, int orderId, string orderNumber, decimal amount)
        {
            try
            {
                _logger.LogInformation($"🔵 RabbitMQ: Pokušaj slanja notifikacije - OrderId={orderId}, SellerId={sellerId}, OrderNumber={orderNumber}, Amount={amount}");

                if (!InitializeConnection())
                {
                    _logger.LogWarning($"⚠️ RabbitMQ: Nije moguće poslati notifikaciju za OrderId={orderId} jer RabbitMQ nije dostupan.");
                    return;
                }

                if (_channel == null || _channel.IsClosed)
                {
                    _logger.LogWarning($"⚠️ RabbitMQ: Channel nije dostupan za OrderId={orderId}.");
                    return;
                }

                var message = new
                {
                    SellerId = sellerId,
                    OrderId = orderId,
                    OrderNumber = orderNumber,
                    Amount = amount,
                    Timestamp = DateTime.UtcNow
                };

                var json = JsonSerializer.Serialize(message);
                var body = Encoding.UTF8.GetBytes(json);

                _logger.LogInformation($"🔵 RabbitMQ: Poruka serijalizovana. JSON: {json}");
                _logger.LogInformation($"🔵 RabbitMQ: Queue name: {_queueName}");

                var properties = _channel.CreateBasicProperties();
                properties.Persistent = true;

                _logger.LogInformation($"🔵 RabbitMQ: Publikovanje poruke u queue: {_queueName}");
                _logger.LogInformation($"🔵 RabbitMQ: Exchange: (default), RoutingKey: {_queueName}, Body size: {body.Length} bytes");

                try
                {
                    _channel.BasicPublish(
                        exchange: "",
                        routingKey: _queueName,
                        basicProperties: properties,
                        body: body
                    );

                    _logger.LogInformation($"✅ RabbitMQ: BasicPublish() pozvan uspješno!");
                    _logger.LogInformation($"✅ RabbitMQ: Poruka uspješno poslana! OrderId={orderId}, SellerId={sellerId}, OrderNumber={orderNumber}, Amount={amount}, Queue={_queueName}");
                }
                catch (Exception publishEx)
                {
                    _logger.LogError(publishEx, $"❌ RabbitMQ: Greška u BasicPublish()! Error: {publishEx.Message}");
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ RabbitMQ: Greška pri slanju poruke za OrderId={orderId}, SellerId={sellerId}, OrderNumber={orderNumber}");
                _logger.LogError($"❌ RabbitMQ: Error details: {ex.Message}");
                _logger.LogError($"❌ RabbitMQ: Stack trace: {ex.StackTrace}");
            }
        }

        public void Dispose()
        {
            _channel?.Close();
            _channel?.Dispose();
            _connection?.Close();
            _connection?.Dispose();
        }
    }
}

