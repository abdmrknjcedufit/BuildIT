using Microsoft.AspNetCore.Authorization;
using Microsoft.OpenApi.Models;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace BuildIT.Filters
{
    public class SwaggerOperationFilter : IOperationFilter
    {
        public void Apply(OpenApiOperation operation, OperationFilterContext context)
        {
            var hasAllowAnonymous = context.MethodInfo
                .GetCustomAttributes(true)
                .OfType<AllowAnonymousAttribute>()
                .Any() ||
                context.MethodInfo.DeclaringType?
                .GetCustomAttributes(true)
                .OfType<AllowAnonymousAttribute>()
                .Any() == true;

            if (hasAllowAnonymous)
            {
                operation.Security = new List<OpenApiSecurityRequirement>();
            }
        }
    }
}

