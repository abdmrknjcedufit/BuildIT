using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class CategoryService : BaseCRUDService<Model.Models.Category, CategorySearchObject, Database.Category, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
    {
        public CategoryService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Category> AddFilter(CategorySearchObject search, IQueryable<Database.Category> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x => x.Description.Contains(fts));
            }

            filteredQuery = filteredQuery.OrderBy(x => x.Description);

            return filteredQuery;
        }

        public override void BeforeInsert(CategoryInsertRequest request, Database.Category entity)
        {
        }

        public override void BeforeUpdate(CategoryUpdateRequest request, Database.Category entity)
        {
            base.BeforeUpdate(request, entity);
        }
    }
}

