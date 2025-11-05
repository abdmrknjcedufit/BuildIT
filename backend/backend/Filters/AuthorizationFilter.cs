using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace BuildIT.Filters
{
    public class AuthorizationFilter : IAuthorizationFilter
    {
        public void OnAuthorization(AuthorizationFilterContext context)
        {
            if (context.ActionDescriptor.EndpointMetadata.Any(em => em is AuthorizeAttribute))
            {
                if (!context.HttpContext.User.Identity?.IsAuthenticated ?? true)
                {
                    context.Result = new JsonResult(new { message = "Potrebna je autentifikacija za pristup ovom resursu." })
                    {
                        StatusCode = (int)HttpStatusCode.Unauthorized
                    };
                    return;
                }

                var authorizeAttributes = context.ActionDescriptor.EndpointMetadata
                    .OfType<AuthorizeAttribute>()
                    .ToList();

                if (authorizeAttributes.Any())
                {
                    var requiredRoles = authorizeAttributes
                        .SelectMany(a => a.Roles?.Split(',') ?? Array.Empty<string>())
                        .Where(r => !string.IsNullOrWhiteSpace(r))
                        .ToList();

                    if (requiredRoles.Any())
                    {
                        var userRoles = context.HttpContext.User.Claims
                            .Where(c => c.Type == System.Security.Claims.ClaimTypes.Role)
                            .Select(c => c.Value)
                            .ToList();

                        var hasRequiredRole = requiredRoles.Any(role => userRoles.Contains(role.Trim()));

                        if (!hasRequiredRole)
                        {
                            var route = context.RouteData.Values["controller"]?.ToString() ?? "";
                            var message = route switch
                            {
                                "Category" => "Samo administratori mogu pristupiti kategorijama. Nemate dozvolu za ovu akciju.",
                                "Subcategory" => "Samo administratori mogu pristupiti podkategorijama. Nemate dozvolu za ovu akciju.",
                                _ => "Nemate dozvolu za pristup ovom resursu. Potrebna je Admin rola."
                            };

                            context.Result = new JsonResult(new { message })
                            {
                                StatusCode = (int)HttpStatusCode.Forbidden
                            };
                        }
                    }
                }
            }
        }
    }
}

