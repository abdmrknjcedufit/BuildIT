using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System;

namespace BuildIT.API.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class CartController : BaseCRUDController<Cart, CartSearchObject, CartInsertRequest, CartUpdateRequest>
{
    public CartController(ICartService service) : base(service)
    {
    }

    [HttpGet]
    [AllowAnonymous]
    public override PagedResult<Cart> GetList([FromQuery] CartSearchObject? search = null)
    {
        return base.GetList(search ?? new CartSearchObject());
    }

    [HttpPost]
    [AllowAnonymous]
    public override Cart Insert([FromBody] CartInsertRequest request)
    {
        return base.Insert(request);
    }

    [HttpGet("{id}")]
    [AllowAnonymous]
    public override Cart GetById(int id)
    {
        return base.GetById(id);
    }

    [HttpPut("{id}")]
    [AllowAnonymous]
    public override Cart Update(int id, [FromBody] CartUpdateRequest request)
    {
        return base.Update(id, request);
    }

    [HttpDelete("{id}")]
    [AllowAnonymous]
    public override IActionResult Delete(int id)
    {
        try
        {
            var service = (ICartService)_service;
            service.DeleteCartItem(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}

