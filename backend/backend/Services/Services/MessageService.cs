using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using BuildIT.Hubs;

namespace BuildIT.Services.Services;

public class MessageService : BaseCRUDService<Model.Models.Message, MessageSearchObject, Database.Message, MessageInsertRequest, MessageUpdateRequest>, IMessageService
{
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly INotificationService _notificationService;

    public MessageService(BuildITDbContext context, IMapper mapper, IHubContext<ChatHub> hubContext, INotificationService notificationService) : base(context, mapper)
    {
        _hubContext = hubContext;
        _notificationService = notificationService;
    }

    public override IQueryable<Database.Message> AddFilter(MessageSearchObject search, IQueryable<Database.Message> query)
    {
        var filteredQuery = base.AddFilter(search, query);

        if (search != null && search.ConversationId.HasValue)
        {
            filteredQuery = filteredQuery.Where(m => m.ConversationId == search.ConversationId.Value);
        }

        if (search != null && search.SenderId.HasValue)
        {
            filteredQuery = filteredQuery.Where(m => m.SenderId == search.SenderId.Value);
        }

        if (search != null && search.IsRead.HasValue)
        {
            filteredQuery = filteredQuery.Where(m => m.IsRead == search.IsRead.Value);
        }

        return filteredQuery.OrderBy(m => m.CreatedAt);
    }

    public override PagedResult<Model.Models.Message> GetPaged(MessageSearchObject search)
    {
        var query = Context.Messages
            .Include(m => m.Sender)
            .Include(m => m.Conversation)
            .AsQueryable();

        query = AddFilter(search, query);

        int count = query.Count();

        if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
        {
            int page = search.Page.Value > 0 ? search.Page.Value - 1 : 0;
            int pageSize = search.PageSize.Value > 0 ? search.PageSize.Value : 10;
            query = query.Skip(page * pageSize).Take(pageSize);
        }

        var list = query.ToList();
        var result = Mapper.Map<List<Model.Models.Message>>(list);

        return new PagedResult<Model.Models.Message>
        {
            ResultList = result,
            Count = count
        };
    }

    public override Model.Models.Message GetById(int id)
    {
        var entity = Context.Messages
            .Include(m => m.Sender)
            .Include(m => m.Conversation)
            .FirstOrDefault(m => m.Id == id);

        if (entity == null)
        {
            throw new Exception("Poruka nije pronađena");
        }

        return Mapper.Map<Model.Models.Message>(entity);
    }

    public override Model.Models.Message Insert(MessageInsertRequest request)
    {
        var conversation = Context.Conversations
            .FirstOrDefault(c => c.Id == request.ConversationId);

        if (conversation == null)
        {
            throw new Exception("Konverzacija nije pronađena");
        }

        if (conversation.User1Id != request.SenderId && conversation.User2Id != request.SenderId)
        {
            throw new Exception("Korisnik nije učesnik u ovoj konverzaciji");
        }

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new Exception("Sadržaj poruke je obavezan");
        }

        var entity = new Database.Message
        {
            ConversationId = request.ConversationId,
            SenderId = request.SenderId,
            Content = request.Content.Trim(),
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        Context.Messages.Add(entity);

        conversation.UpdatedAt = DateTime.UtcNow;
        Context.Conversations.Update(conversation);

        Context.SaveChanges();

        var savedMessage = GetById(entity.Id);

        var recipientId = conversation.User1Id == request.SenderId ? conversation.User2Id : conversation.User1Id;

        try
        {
            var sender = Context.Users.FirstOrDefault(u => u.Id == request.SenderId);
            var senderName = sender != null ? $"{sender.FirstName} {sender.LastName}".Trim() : "Korisnik";
            var messagePreview = request.Content.Length > 50 ? request.Content.Substring(0, 50) + "..." : request.Content;

            var notificationRequest = new NotificationInsertRequest
            {
                UserId = recipientId,
                Title = "💬 Nova poruka",
                Message = $"{senderName} vam je poslao poruku: {messagePreview}",
                NotificationType = "Message",
                ReferenceId = savedMessage.ConversationId,
                Priority = "Normal",
                IsRead = false,
                IsSent = true
            };

            _notificationService.Insert(notificationRequest);
        }
        catch
        {
        }

        _ = Task.Run(async () =>
        {
            try
            {
                await _hubContext.Clients.Group($"conversation_{request.ConversationId}").SendAsync("ReceiveMessage", new
                {
                    id = savedMessage.Id,
                    conversationId = savedMessage.ConversationId,
                    senderId = savedMessage.SenderId,
                    content = savedMessage.Content,
                    isRead = savedMessage.IsRead,
                    createdAt = savedMessage.CreatedAt,
                    sender = savedMessage.Sender != null ? new
                    {
                        id = savedMessage.Sender.Id,
                        firstName = savedMessage.Sender.FirstName,
                        lastName = savedMessage.Sender.LastName,
                        username = savedMessage.Sender.Username
                    } : null
                });
            }
            catch
            {
            }
        });

        return savedMessage;
    }

    public void MarkAsRead(int messageId, int userId)
    {
        var message = Context.Messages
            .Include(m => m.Conversation)
            .FirstOrDefault(m => m.Id == messageId);

        if (message == null)
        {
            throw new Exception("Poruka nije pronađena");
        }

        if (message.SenderId == userId)
        {
            return;
        }

        if (message.Conversation.User1Id != userId && message.Conversation.User2Id != userId)
        {
            throw new Exception("Korisnik nije učesnik u ovoj konverzaciji");
        }

        message.IsRead = true;
        Context.Messages.Update(message);
        Context.SaveChanges();
    }

    public void MarkConversationAsRead(int conversationId, int userId)
    {
        var conversation = Context.Conversations
            .FirstOrDefault(c => c.Id == conversationId);

        if (conversation == null)
        {
            throw new Exception("Konverzacija nije pronađena");
        }

        if (conversation.User1Id != userId && conversation.User2Id != userId)
        {
            throw new Exception("Korisnik nije učesnik u ovoj konverzaciji");
        }

        var messages = Context.Messages
            .Where(m => m.ConversationId == conversationId && 
                       m.SenderId != userId && 
                       !m.IsRead)
            .ToList();

        foreach (var message in messages)
        {
            message.IsRead = true;
        }

        Context.Messages.UpdateRange(messages);
        Context.SaveChanges();
    }

    public override void BeforeInsert(MessageInsertRequest request, Database.Message entity)
    {
        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new Exception("Sadržaj poruke je obavezan");
        }

        entity.CreatedAt = DateTime.UtcNow;
    }
}

