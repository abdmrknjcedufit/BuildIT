using BuildIT.Model.SearchObjects;

namespace BuildIT.Model.SearchObjects;

public class MessageSearchObject : BaseSearchObject
{
    public int? ConversationId { get; set; }
    public int? SenderId { get; set; }
    public bool? IsRead { get; set; }
}

