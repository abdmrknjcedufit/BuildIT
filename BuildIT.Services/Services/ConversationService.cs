using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services;

public class ConversationService : BaseCRUDService<Model.Models.Conversation, ConversationSearchObject, Database.Conversation, ConversationInsertRequest, BaseUpdateRequest>, IConversationService
{
    public ConversationService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
    {
    }

    public override IQueryable<Database.Conversation> AddFilter(ConversationSearchObject search, IQueryable<Database.Conversation> query)
    {
        var filteredQuery = base.AddFilter(search, query);

        if (search != null && search.UserId.HasValue)
        {
            filteredQuery = filteredQuery.Where(c => c.User1Id == search.UserId.Value || c.User2Id == search.UserId.Value);
        }

        if (search != null && search.ListingId.HasValue)
        {
            filteredQuery = filteredQuery.Where(c => c.ListingId == search.ListingId.Value);
        }

        return filteredQuery.OrderByDescending(c => c.UpdatedAt ?? c.CreatedAt);
    }

    public override PagedResult<Model.Models.Conversation> GetPaged(ConversationSearchObject search)
    {
        var query = Context.Conversations
            .Include(c => c.User1)
            .Include(c => c.User2)
            .Include(c => c.Listing!)
                .ThenInclude(l => l.Item)
            .Include(c => c.Messages.OrderByDescending(m => m.CreatedAt).Take(1))
                .ThenInclude(m => m.Sender)
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
        var result = new List<Model.Models.Conversation>();

        foreach (var conv in list)
        {
            var mapped = Mapper.Map<Model.Models.Conversation>(conv);
            
            var unreadCount = Context.Messages
                .Count(m => m.ConversationId == conv.Id && 
                           m.SenderId != search!.UserId && 
                           !m.IsRead);
            mapped.UnreadCount = unreadCount;

            if (conv.Messages.Any())
            {
                mapped.LastMessage = Mapper.Map<Model.Models.Message>(conv.Messages.First());
            }

            result.Add(mapped);
        }

        return new PagedResult<Model.Models.Conversation>
        {
            ResultList = result,
            Count = count
        };
    }

    public override Model.Models.Conversation GetById(int id)
    {
        var entity = Context.Conversations
            .Include(c => c.User1)
            .Include(c => c.User2)
            .Include(c => c.Listing!)
                .ThenInclude(l => l.Item)
            .Include(c => c.Messages.OrderBy(m => m.CreatedAt))
                .ThenInclude(m => m.Sender)
            .FirstOrDefault(c => c.Id == id);

        if (entity == null)
        {
            throw new Exception("Konverzacija nije pronađena");
        }

        return Mapper.Map<Model.Models.Conversation>(entity);
    }

    public Model.Models.Conversation GetOrCreateConversation(int user1Id, int user2Id, int? listingId = null)
    {
        if (user1Id == user2Id)
        {
            throw new Exception("Korisnik ne može kreirati konverzaciju sa samim sobom");
        }

        var existing = Context.Conversations
            .FirstOrDefault(c => 
                ((c.User1Id == user1Id && c.User2Id == user2Id) ||
                 (c.User1Id == user2Id && c.User2Id == user1Id)) &&
                (listingId == null || c.ListingId == listingId));

        if (existing != null)
        {
            return GetById(existing.Id);
        }

        var entity = new Database.Conversation
        {
            User1Id = user1Id,
            User2Id = user2Id,
            ListingId = listingId,
            CreatedAt = DateTime.UtcNow
        };

        Context.Conversations.Add(entity);
        Context.SaveChanges();

        return GetById(entity.Id);
    }

    public override void BeforeInsert(ConversationInsertRequest request, Database.Conversation entity)
    {
        if (request.User1Id == request.User2Id)
        {
            throw new Exception("Korisnik ne može kreirati konverzaciju sa samim sobom");
        }

        var user1Exists = Context.Users.Any(u => u.Id == request.User1Id);
        var user2Exists = Context.Users.Any(u => u.Id == request.User2Id);

        if (!user1Exists || !user2Exists)
        {
            throw new Exception("Jedan ili oba korisnika ne postoje");
        }

        if (request.ListingId.HasValue)
        {
            var listingExists = Context.Listings.Any(l => l.Id == request.ListingId.Value);
            if (!listingExists)
            {
                throw new Exception("Oglas nije pronađen");
            }
        }

        entity.CreatedAt = DateTime.UtcNow;
    }
}

