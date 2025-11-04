using BuildIT.Model;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace BuildIT.Filters
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

            if (context.Exception is UserException)
            {
                context.ModelState.AddModelError("userError", context.Exception.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
            }
            else
            {
                context.ModelState.AddModelError("ERROR", "Greška na serveru, molimo provjerite logove");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
            }

            var list = context.ModelState.Where(x => x.Value!.Errors.Count() > 0)
                .ToDictionary(x => x.Key, y => y.Value!.Errors.Select(z => z.ErrorMessage));

            context.Result = new JsonResult(new { errors = list });
        }
    }
}

