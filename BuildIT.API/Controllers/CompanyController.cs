using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CompanyController : BaseCRUDController<Company, CompanySearchObject, CompanyInsertRequest, CompanyUpdateRequest>
    {
        protected new ICompanyService _service;
        public CompanyController(ICompanyService service) : base(service)
        {
            _service = service;
        }
    }
}

