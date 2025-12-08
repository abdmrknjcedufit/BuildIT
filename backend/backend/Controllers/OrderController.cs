using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OrderController : BaseCRUDController<Order, OrderSearchObject, OrderInsertRequest, OrderUpdateRequest>
    {
        protected new IOrderService _service;
        public OrderController(IOrderService service) : base(service)
        {
            _service = service;
        }
    }
}
