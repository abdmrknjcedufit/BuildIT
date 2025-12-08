using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Admin")]
    public class SubcategoryController : BaseCRUDController<Subcategory, SubcategorySearchObject, SubcategoryInsertRequest, SubcategoryUpdateRequest>
    {
        protected new ISubcategoryService _service;
        public SubcategoryController(ISubcategoryService service) : base(service)
        {
            _service = service;
        }
    }
}

