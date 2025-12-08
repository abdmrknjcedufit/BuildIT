using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Admin")]
    public class CategoryController : BaseCRUDController<Category, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>
    {
        protected new ICategoryService _service;
        public CategoryController(ICategoryService service) : base(service)
        {
            _service = service;
        }
    }
}

