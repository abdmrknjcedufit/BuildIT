using BuildIT.Model;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

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

        public override Model.Models.Order GetById(int id)
        {
            var entity = Context.Orders
                .Include(x => x.User)
                .Include(x => x.Transaction!)
                    .ThenInclude(t => t.Listing!)
                        .ThenInclude(l => l.Item)
                .Include(x => x.Transaction!)
                    .ThenInclude(t => t.Seller)
                .Include(x => x.DeliveryProvider)
                .FirstOrDefault(x => x.Id == id);

            if (entity == null)
            {
                throw new UserException("Narudžba nije pronađena");
            }

            var mappedOrder = new Model.Models.Order
            {
                Id = entity.Id,
                UserId = entity.UserId,
                OrderNumber = entity.OrderNumber,
                Status = entity.Status,
                OrderType = entity.OrderType,
                TotalAmount = entity.TotalAmount,
                DiscountAmount = entity.DiscountAmount,
                TaxAmount = entity.TaxAmount,
                FinalAmount = entity.FinalAmount,
                PaymentMethod = entity.PaymentMethod,
                PaymentStatus = entity.PaymentStatus,
                TransactionId = entity.TransactionId,
                ShippingAddress = entity.ShippingAddress,
                BillingAddress = entity.BillingAddress,
                ExpectedDeliveryDate = entity.ExpectedDeliveryDate,
                CreatedAt = entity.CreatedAt,
                UpdatedAt = entity.UpdatedAt,
                IsInvoiceGenerated = entity.IsInvoiceGenerated,
                Priority = entity.Priority,
                DeliveryProviderId = entity.DeliveryProviderId,
                DeliveryType = entity.DeliveryType,
                User = entity.User != null ? Mapper.Map<Model.Models.User>(entity.User) : null,
                Transaction = entity.Transaction != null ? new Model.Models.Transaction
                {
                    Id = entity.Transaction.Id,
                    ListingId = entity.Transaction.ListingId,
                    BuyerId = entity.Transaction.BuyerId,
                    SellerId = entity.Transaction.SellerId,
                    Amount = entity.Transaction.Amount,
                    Status = entity.Transaction.Status,
                    PaymentMethod = entity.Transaction.PaymentMethod,
                    Type = entity.Transaction.Type,
                    TransactionDate = entity.Transaction.TransactionDate,
                    StripeTransactionId = entity.Transaction.StripeTransactionId,
                    CreatedAt = entity.Transaction.CreatedAt,
                    Listing = entity.Transaction.Listing != null ? Mapper.Map<Model.Models.Listing>(entity.Transaction.Listing) : null,
                    Seller = entity.Transaction.Seller != null ? Mapper.Map<Model.Models.User>(entity.Transaction.Seller) : null
                } : null,
                DeliveryProvider = entity.DeliveryProvider != null ? Mapper.Map<Model.Models.DeliveryProvider>(entity.DeliveryProvider) : null
            };

            return mappedOrder;
        }
    }
}

