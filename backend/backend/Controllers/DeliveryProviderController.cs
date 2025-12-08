using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class DeliveryProviderController : BaseCRUDController<DeliveryProvider, DeliveryProviderSearchObject, DeliveryProviderInsertRequest, DeliveryProviderUpdateRequest>
{
    public DeliveryProviderController(IDeliveryProviderService service) : base(service)
    {
    }

    [HttpGet]
    [AllowAnonymous]
    public override PagedResult<DeliveryProvider> GetList([FromQuery] DeliveryProviderSearchObject? search = null)
    {
        return base.GetList(search ?? new DeliveryProviderSearchObject());
    }

    [HttpGet("{id}")]
    [AllowAnonymous]
    public override DeliveryProvider GetById(int id)
    {
        return base.GetById(id);
    }
}

