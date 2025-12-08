using Microsoft.AspNetCore.SignalR;

namespace BuildIT.Services.Hubs;

public class ChatHub : Hub
{
    public async Task JoinConversation(int conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"conversation_{conversationId}");
    }

    public async Task LeaveConversation(int conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conversation_{conversationId}");
    }

    public async Task SendMessage(int conversationId, int senderId, string content, DateTime createdAt)
    {
        await Clients.Group($"conversation_{conversationId}").SendAsync("ReceiveMessage", new
        {
            conversationId = conversationId,
            senderId = senderId,
            content = content,
            createdAt = createdAt
        });
    }

    public async Task MessageRead(int conversationId, int messageId, int userId)
    {
        await Clients.Group($"conversation_{conversationId}").SendAsync("MessageRead", new
        {
            conversationId = conversationId,
            messageId = messageId,
            userId = userId
        });
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}

