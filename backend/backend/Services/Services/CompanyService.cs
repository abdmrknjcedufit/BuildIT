using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using CompanyModel = BuildIT.Model.Models.Company;

namespace BuildIT.Services.Services
{
    public class CompanyService : BaseCRUDService<CompanyModel, CompanySearchObject, Database.Company, CompanyInsertRequest, CompanyUpdateRequest>, ICompanyService
    {
        public CompanyService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Company> AddFilter(CompanySearchObject search, IQueryable<Database.Company> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.Name.Contains(fts) ||
                    (x.PIB != null && x.PIB.Contains(fts)) ||
                    (x.Email != null && x.Email.Contains(fts)));
            }

            if (search != null && search.IsActive.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsActive == search.IsActive.Value);
            }

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            filteredQuery = filteredQuery.OrderByDescending(c => c.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(CompanyInsertRequest request, Database.Company entity)
        {
            var existingCompany = Context.Companies
                .FirstOrDefault(c => c.UserId == request.UserId && c.IsActive);

            if (existingCompany != null)
            {
                throw new UserException("Korisnik već ima aktivnu kompaniju.");
            }

            entity.IsActive = true;
            entity.CreatedAt = DateTime.UtcNow;
        }

        public override void BeforeUpdate(CompanyUpdateRequest request, Database.Company entity)
        {
            base.BeforeUpdate(request, entity);
        }
    }
}

