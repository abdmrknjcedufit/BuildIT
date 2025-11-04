using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface ICompanyService : ICRUDService<Model.Models.Company, CompanySearchObject, CompanyInsertRequest, CompanyUpdateRequest>
    {
    }
}

