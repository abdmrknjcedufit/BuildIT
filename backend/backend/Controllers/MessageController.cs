using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class MessageController : BaseCRUDController<Message, MessageSearchObject, MessageInsertRequest, MessageUpdateRequest>
{
    protected new IMessageService _service;
    
    public MessageController(IMessageService service) : base(service)
    {
        _service = service;
    }

    [HttpPost("{id}/mark-read")]
    [AllowAnonymous]
    public IActionResult MarkAsRead(int id, [FromQuery] int userId)
    {
        try
        {
            _service.MarkAsRead(id, userId);
            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("conversation/{conversationId}/mark-read")]
    [AllowAnonymous]
    public IActionResult MarkConversationAsRead(int conversationId, [FromQuery] int userId)
    {
        try
        {
            _service.MarkConversationAsRead(conversationId, userId);
            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

