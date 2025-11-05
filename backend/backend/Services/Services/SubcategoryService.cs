using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class SubcategoryService : BaseCRUDService<Model.Models.Subcategory, SubcategorySearchObject, Database.Subcategory, SubcategoryInsertRequest, SubcategoryUpdateRequest>, ISubcategoryService
    {
        public SubcategoryService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Subcategory> AddFilter(SubcategorySearchObject search, IQueryable<Database.Subcategory> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x => x.Description.Contains(fts));
            }

            if (search != null && search.CategoryId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CategoryId == search.CategoryId.Value);
            }

            filteredQuery = filteredQuery.OrderBy(x => x.Description);

            return filteredQuery;
        }

        public override void BeforeInsert(SubcategoryInsertRequest request, Database.Subcategory entity)
        {
            var categoryExists = Context.Categories.Any(c => c.Id == request.CategoryId);
            if (!categoryExists)
            {
                throw new UserException("Kategorija nije pronađena.");
            }
        }

        public override void BeforeUpdate(SubcategoryUpdateRequest request, Database.Subcategory entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.CategoryId.HasValue)
            {
                var categoryExists = Context.Categories.Any(c => c.Id == request.CategoryId.Value);
                if (!categoryExists)
                {
                    throw new UserException("Kategorija nije pronađena.");
                }
                entity.CategoryId = request.CategoryId.Value;
            }
        }
    }
}

