using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces;

public interface IMessageService : ICRUDService<Message, MessageSearchObject, MessageInsertRequest, MessageUpdateRequest>
{
    void MarkAsRead(int messageId, int userId);
    void MarkConversationAsRead(int conversationId, int userId);
}

