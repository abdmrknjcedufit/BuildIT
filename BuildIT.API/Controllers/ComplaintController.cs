using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ComplaintController : BaseCRUDController<Complaint, ComplaintSearchObject, ComplaintInsertRequest, ComplaintUpdateRequest>
    {
        protected new IComplaintService _service;
        public ComplaintController(IComplaintService service) : base(service)
        {
            _service = service;
        }
    }
}

