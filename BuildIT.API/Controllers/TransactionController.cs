using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace BuildIT.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class TransactionController : BaseCRUDController<Transaction, TransactionSearchObject, TransactionInsertRequest, TransactionUpdateRequest>
    {
        protected new ITransactionService _service;
        public TransactionController(ITransactionService service) : base(service)
        {
            _service = service;
        }
    }
}

