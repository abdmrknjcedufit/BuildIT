using System.Net;
using System.Security.Claims;
using System.Text.Json;
using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc.Filters;

namespace BuildIT.API.Filters
{
    public class AuditLogActionFilter : IAsyncActionFilter
    {
        private readonly IAuditLogService _auditLogService;
        private readonly ILogger<AuditLogActionFilter> _logger;

        public AuditLogActionFilter(IAuditLogService auditLogService, ILogger<AuditLogActionFilter> logger)
        {
            _auditLogService = auditLogService;
            _logger = logger;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var controllerName = context.ActionDescriptor.DisplayName ?? context.HttpContext.Request.Path;

            string? requestData = null;
            try
            {
                if (context.ActionArguments?.Count > 0)
                {
                    requestData = JsonSerializer.Serialize(context.ActionArguments, new JsonSerializerOptions
                    {
                        WriteIndented = false,
                        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to serialize action arguments for audit log.");
            }

            var executedContext = await next();

            try
            {
                var userIdClaim = context.HttpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                int? userId = null;
                if (int.TryParse(userIdClaim, out var parsedUserId))
                {
                    userId = parsedUserId;
                }

                var username = context.HttpContext.User.Identity?.IsAuthenticated == true
                    ? context.HttpContext.User.Identity.Name
                    : null;

                var entityId = context.RouteData.Values.TryGetValue("id", out var idValue) ? idValue?.ToString() : null;

                int statusCode;
                string message;

                if (executedContext.Exception != null)
                {
                    if (executedContext.Exception is UserException)
                    {
                        statusCode = (int)HttpStatusCode.BadRequest;
                    }
                    else
                    {
                        statusCode = (int)HttpStatusCode.InternalServerError;
                    }

                    message = executedContext.Exception.Message;
                }
                else
                {
                    statusCode = executedContext.HttpContext.Response.StatusCode;

                    if (executedContext.Result is Microsoft.AspNetCore.Mvc.ObjectResult objectResult)
                    {
                        if (objectResult.StatusCode.HasValue)
                        {
                            statusCode = objectResult.StatusCode.Value;
                        }

                        message = objectResult.Value != null ? $"Result: {objectResult.StatusCode}" : "Success";
                    }
                    else
                    {
                        message = "Success";
                    }
                }

                var actionDescriptor = $"{context.HttpContext.Request.Method} {context.HttpContext.Request.Path}";

                var logRequest = new AuditLogInsertRequest
                {
                    UserId = userId,
                    Username = username,
                    Action = actionDescriptor,
                    EntityId = entityId,
                    RequestData = requestData,
                    ResponseStatus = statusCode.ToString(),
                    Message = message
                };

                await _auditLogService.LogAsync(logRequest);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to write audit log for action {Action}", controllerName);
            }
        }
    }
}

