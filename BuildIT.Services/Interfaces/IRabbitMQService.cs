namespace BuildIT.Services.Interfaces
{
    public interface IRabbitMQService
    {
        void PublishOrderNotification(int sellerId, int orderId, string orderNumber, decimal amount);
    }
}

