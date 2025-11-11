using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;

namespace BuildIT.Services.Services
{
    public class OrderService : BaseCRUDService<Model.Models.Order, OrderSearchObject, Database.Order, OrderInsertRequest, OrderUpdateRequest>, IOrderService
    {
        public OrderService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.Order> AddFilter(OrderSearchObject search, IQueryable<Database.Order> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (search != null && search.UserId.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.UserId == search.UserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search?.Status))
            {
                filteredQuery = filteredQuery.Where(x => x.Status == search.Status);
            }

            if (!string.IsNullOrWhiteSpace(search?.OrderType))
            {
                filteredQuery = filteredQuery.Where(x => x.OrderType == search.OrderType);
            }

            if (!string.IsNullOrWhiteSpace(search?.PaymentStatus))
            {
                filteredQuery = filteredQuery.Where(x => x.PaymentStatus == search.PaymentStatus);
            }

            if (!string.IsNullOrWhiteSpace(search?.Priority))
            {
                filteredQuery = filteredQuery.Where(x => x.Priority == search.Priority);
            }

            if (search != null && search.FromDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CreatedAt.Date >= search.FromDate.Value.Date);
            }

            if (search != null && search.ToDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.CreatedAt.Date <= search.ToDate.Value.Date);
            }

            filteredQuery = filteredQuery.OrderByDescending(x => x.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(OrderInsertRequest request, Database.Order entity)
        {
            var userExists = Context.Users.Any(u => u.Id == request.UserId);
            if (!userExists)
            {
                throw new UserException("Korisnik nije pronađen.");
            }

            if (string.IsNullOrWhiteSpace(request.OrderNumber))
            {
                throw new UserException("Broj narudžbe je obavezan.");
            }

            if (request.FinalAmount <= 0)
            {
                throw new UserException("Konačni iznos mora biti veći od 0.");
            }

            if (string.IsNullOrWhiteSpace(request.PaymentMethod))
            {
                throw new UserException("Način plaćanja je obavezan.");
            }

            entity.CreatedAt = DateTime.UtcNow;
            entity.UpdatedAt = null;
        }

        public override void BeforeUpdate(OrderUpdateRequest request, Database.Order entity)
        {
            base.BeforeUpdate(request, entity);

            if (request.TotalAmount.HasValue)
            {
                entity.TotalAmount = request.TotalAmount.Value;
            }

            if (request.DiscountAmount.HasValue)
            {
                entity.DiscountAmount = request.DiscountAmount.Value;
            }

            if (request.TaxAmount.HasValue)
            {
                entity.TaxAmount = request.TaxAmount.Value;
            }

            if (request.FinalAmount.HasValue)
            {
                entity.FinalAmount = request.FinalAmount.Value;
            }

            if (request.PaymentMethod != null)
            {
                entity.PaymentMethod = request.PaymentMethod;
            }

            if (request.PaymentStatus != null)
            {
                entity.PaymentStatus = request.PaymentStatus;
            }

            if (request.TransactionId.HasValue)
            {
                entity.TransactionId = request.TransactionId.Value;
            }

            if (request.ShippingAddress != null)
            {
                entity.ShippingAddress = request.ShippingAddress;
            }

            if (request.BillingAddress != null)
            {
                entity.BillingAddress = request.BillingAddress;
            }

            if (request.ExpectedDeliveryDate.HasValue)
            {
                entity.ExpectedDeliveryDate = request.ExpectedDeliveryDate.Value;
            }

            if (request.IsInvoiceGenerated.HasValue)
            {
                entity.IsInvoiceGenerated = request.IsInvoiceGenerated.Value;
            }

            if (request.Priority != null)
            {
                entity.Priority = request.Priority;
            }

            entity.UpdatedAt = DateTime.UtcNow;
        }
    }
}
