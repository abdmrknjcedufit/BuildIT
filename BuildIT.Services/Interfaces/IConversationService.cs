using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces;

public interface IConversationService : ICRUDService<Conversation, ConversationSearchObject, ConversationInsertRequest, BaseUpdateRequest>
{
    Model.Models.Conversation GetOrCreateConversation(int user1Id, int user2Id, int? listingId = null);
}

