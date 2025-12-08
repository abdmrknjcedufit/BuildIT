using BuildIT.Model;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace BuildIT.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        ILogger<ExceptionFilter> _logger;
        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }
        public override void OnException(ExceptionContext context)
        {
            _logger.LogError(context.Exception, context.Exception.Message);
            _logger.LogError("Exception Type: {Type}", context.Exception.GetType().Name);
            _logger.LogError("Exception StackTrace: {StackTrace}", context.Exception.StackTrace);

            if (context.Exception is UserException)
            {
                context.ModelState.AddModelError("userError", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else
            {
                var errorMessage = "Greška na serveru, molimo provjerite logove";
                if (context.HttpContext.RequestServices.GetService<IHostEnvironment>()?.IsDevelopment() == true)
                {
                    errorMessage = context.Exception.Message + (context.Exception.InnerException != null ? " | Inner: " + context.Exception.InnerException.Message : "");
                }
                context.ModelState.AddModelError("ERROR", errorMessage);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            var list = context.ModelState.Where(x => x.Value!.Errors.Count() > 0)
                .ToDictionary(x => x.Key, y => y.Value!.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}

