using Microsoft.AspNetCore.Mvc;
using BuildIT.Services.Interfaces;
using RabbitMQ.Client;
using Microsoft.Extensions.Configuration;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TestRabbitMQController : ControllerBase
    {
        private readonly IRabbitMQService _rabbitMQService;
        private readonly ILogger<TestRabbitMQController> _logger;
        private readonly IConfiguration _configuration;

        public TestRabbitMQController(IRabbitMQService rabbitMQService, ILogger<TestRabbitMQController> logger, IConfiguration configuration)
        {
            _rabbitMQService = rabbitMQService;
            _logger = logger;
            _configuration = configuration;
        }

        [HttpPost("send-test-message")]
        public IActionResult SendTestMessage([FromBody] TestRabbitMQRequest request)
        {
            try
            {
                _logger.LogInformation($"🔵 TEST-RABBITMQ: Počinje slanje test poruke - SellerId: {request.SellerId}, OrderId: {request.OrderId}");

                _rabbitMQService.PublishOrderNotification(
                    request.SellerId,
                    request.OrderId,
                    request.OrderNumber ?? $"TEST-ORD-{DateTime.Now:yyyyMMddHHmmss}",
                    request.Amount
                );

                _logger.LogInformation($"✅ TEST-RABBITMQ: Test poruka poslana!");

                Task.Delay(500).Wait();

                var queueInfo = CheckQueueStatus();
                
                return Ok(new
                {
                    success = true,
                    message = "Test poruka uspješno poslana u RabbitMQ.",
                    queueInfo = queueInfo,
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ TEST-RABBITMQ: Greška pri slanju test poruke: {ex.Message}");
                return BadRequest(new
                {
                    success = false,
                    message = $"Greška pri slanju test poruke: {ex.Message}",
                    details = ex.ToString()
                });
            }
        }

        [HttpGet("check-queue")]
        public IActionResult CheckQueue()
        {
            try
            {
                var queueInfo = CheckQueueStatus();
                return Ok(queueInfo);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ TEST-RABBITMQ: Greška pri provjeri queue-a: {ex.Message}");
                return BadRequest(new
                {
                    success = false,
                    error = ex.Message
                });
            }
        }

        private object CheckQueueStatus()
        {
            try
            {
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

                return new
                {
                    queueName = queueName,
                    messageCount = queueDeclareOk.MessageCount,
                    consumerCount = queueDeclareOk.ConsumerCount,
                    exists = true
                };
            }
            catch (Exception ex)
            {
                return new
                {
                    queueName = "order_notifications",
                    exists = false,
                    error = ex.Message
                };
            }
        }
    }

    public class TestRabbitMQRequest
    {
        public int SellerId { get; set; }
        public int OrderId { get; set; }
        public string? OrderNumber { get; set; }
        public decimal Amount { get; set; }
    }
}

