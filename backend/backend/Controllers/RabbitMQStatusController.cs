using Microsoft.AspNetCore.Mvc;
using RabbitMQ.Client;
using BuildIT.Services.Interfaces;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class RabbitMQStatusController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<RabbitMQStatusController> _logger;

        public RabbitMQStatusController(IConfiguration configuration, ILogger<RabbitMQStatusController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        [HttpGet("check-connection")]
        public IActionResult CheckConnection()
        {
            try
            {
                var hostName = _configuration["RabbitMQ:HostName"] ?? "localhost";
                var port = int.Parse(_configuration["RabbitMQ:Port"] ?? "5672");
                var userName = _configuration["RabbitMQ:UserName"] ?? "guest";
                var password = _configuration["RabbitMQ:Password"] ?? "guest";

                _logger.LogInformation($"🔵 RABBITMQ-STATUS: Provjera konekcije - Host: {hostName}, Port: {port}");

                var factory = new ConnectionFactory
                {
                    HostName = hostName,
                    Port = port,
                    UserName = userName,
                    Password = password
                };

                using var connection = factory.CreateConnection();
                using var channel = connection.CreateModel();

                var queueName = "order_notifications";
                
                channel.QueueDeclare(
                    queue: queueName,
                    durable: true,
                    exclusive: false,
                    autoDelete: false,
                    arguments: null
                );

                var queueDeclareOk = channel.QueueDeclarePassive(queueName);
                var messageCount = queueDeclareOk.MessageCount;
                var consumerCount = queueDeclareOk.ConsumerCount;

                _logger.LogInformation($"✅ RABBITMQ-STATUS: Konekcija uspješna! Queue: {queueName}, Messages: {messageCount}, Consumers: {consumerCount}");

                return Ok(new
                {
                    success = true,
                    connected = true,
                    queueName = queueName,
                    messageCount = messageCount,
                    consumerCount = consumerCount,
                    host = hostName,
                    port = port
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ RABBITMQ-STATUS: Greška pri provjeri konekcije: {ex.Message}");
                return BadRequest(new
                {
                    success = false,
                    connected = false,
                    error = ex.Message,
                    details = ex.ToString()
                });
            }
        }

        [HttpPost("send-test-and-check")]
        public IActionResult SendTestAndCheck([FromServices] IRabbitMQService rabbitMQService)
        {
            try
            {
                _logger.LogInformation($"🔵 RABBITMQ-STATUS: Slanje test poruke i provjera...");

                rabbitMQService.PublishOrderNotification(999, 999, "TEST-STATUS", 99.99m);

                Task.Delay(1000).Wait();

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

                using var connection = factory.CreateConnection();
                using var channel = connection.CreateModel();

                var queueName = "order_notifications";
                var queueDeclareOk = channel.QueueDeclarePassive(queueName);
                var messageCount = queueDeclareOk.MessageCount;

                return Ok(new
                {
                    success = true,
                    messageSent = true,
                    queueName = queueName,
                    messageCount = messageCount,
                    message = messageCount > 0 
                        ? $"Poruka je u queue-u! Ima {messageCount} poruka." 
                        : "Poruka nije u queue-u. Provjeri logove za greške."
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ RABBITMQ-STATUS: Greška: {ex.Message}");
                return BadRequest(new
                {
                    success = false,
                    error = ex.Message,
                    details = ex.ToString()
                });
            }
        }
    }
}

