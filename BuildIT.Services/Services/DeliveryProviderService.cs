using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services;

public class DeliveryProviderService : BaseCRUDService<Model.Models.DeliveryProvider, DeliveryProviderSearchObject, Database.DeliveryProvider, DeliveryProviderInsertRequest, DeliveryProviderUpdateRequest>, IDeliveryProviderService
{
    public DeliveryProviderService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
    {
    }

    public override IQueryable<Database.DeliveryProvider> AddFilter(DeliveryProviderSearchObject search, IQueryable<Database.DeliveryProvider> query)
    {
        var filteredQuery = base.AddFilter(search, query);

        if (search != null && search.IsActive.HasValue)
        {
            filteredQuery = filteredQuery.Where(x => x.IsActive == search.IsActive.Value);
        }

        return filteredQuery;
    }

    public override void BeforeInsert(DeliveryProviderInsertRequest request, Database.DeliveryProvider entity)
    {
        base.BeforeInsert(request, entity);
        entity.CreatedAt = DateTime.UtcNow;
    }

    public override void BeforeUpdate(DeliveryProviderUpdateRequest request, Database.DeliveryProvider entity)
    {
        base.BeforeUpdate(request, entity);
        entity.UpdatedAt = DateTime.UtcNow;
    }
}

