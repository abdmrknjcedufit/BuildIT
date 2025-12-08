using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IAuditLogService : IService<BuildIT.Model.Models.AuditLog, AuditLogSearchObject>
    {
        Task LogAsync(AuditLogInsertRequest request);
    }
}

