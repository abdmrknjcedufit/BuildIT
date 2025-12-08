using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.API.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class ConversationController : BaseCRUDController<Conversation, ConversationSearchObject, ConversationInsertRequest, BaseUpdateRequest>
{
    protected new IConversationService _service;
    
    public ConversationController(IConversationService service) : base(service)
    {
        _service = service;
    }

    [HttpPost("get-or-create")]
    [AllowAnonymous]
    public IActionResult GetOrCreate([FromBody] ConversationInsertRequest request)
    {
        try
        {
            var conversation = _service.GetOrCreateConversation(
                request.User1Id, 
                request.User2Id, 
                request.ListingId);
            return Ok(conversation);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

