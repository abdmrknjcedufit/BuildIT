using BuildIT.Model.Models;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Admin")]
    public class AuditLogController : BaseController<BuildIT.Model.Models.AuditLog, AuditLogSearchObject>
    {
        protected new IAuditLogService _service;
        public AuditLogController(IAuditLogService service) : base(service)
        {
            _service = service;
        }
    }
}
