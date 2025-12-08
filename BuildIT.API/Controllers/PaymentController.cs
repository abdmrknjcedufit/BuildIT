using BuildIT.Model.Requests;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Stripe;
using Stripe.Checkout;

namespace BuildIT.API.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class PaymentController : ControllerBase
{
    private readonly IConfiguration _configuration;
    private readonly BuildITDbContext _context;
    private readonly IOrderService _orderService;
    private readonly ICartService _cartService;
    private readonly ITransactionService _transactionService;
    private readonly IRabbitMQService _rabbitMQService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<PaymentController> _logger;

    public PaymentController(IConfiguration configuration, BuildITDbContext context, IOrderService orderService, ICartService cartService, ITransactionService transactionService, IRabbitMQService rabbitMQService, INotificationService notificationService, ILogger<PaymentController> logger)
    {
        _configuration = configuration;
        _context = context;
        _orderService = orderService;
        _cartService = cartService;
        _transactionService = transactionService;
        _rabbitMQService = rabbitMQService;
        _notificationService = notificationService;
        _logger = logger;
        StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
    }

    [HttpPost("create-checkout-session")]
    [AllowAnonymous]
    public IActionResult CreateCheckoutSession([FromBody] CreateCheckoutSessionRequest request)
    {
        try
        {
            _logger.LogInformation($"🔵 CHECKOUT-SESSION: Kreiranje checkout sesije za userId={request.UserId}, amount={request.Amount}, cartIds={string.Join(",", request.CartIds)}");
            
            var metadata = new Dictionary<string, string>
            {
                { "userId", request.UserId.ToString() },
                { "cartIds", string.Join(",", request.CartIds) },
            };

            if (request.DeliveryProviderId.HasValue)
            {
                metadata["deliveryProviderId"] = request.DeliveryProviderId.Value.ToString();
            }

            if (!string.IsNullOrEmpty(request.DeliveryType))
            {
                metadata["deliveryType"] = request.DeliveryType;
            }

            if (!string.IsNullOrEmpty(request.ShippingAddress))
            {
                metadata["shippingAddress"] = request.ShippingAddress;
            }

            _logger.LogInformation($"🔵 CHECKOUT-SESSION: Metadata: userId={metadata["userId"]}, cartIds={metadata["cartIds"]}, deliveryType={metadata.GetValueOrDefault("deliveryType", "N/A")}");

            var options = new SessionCreateOptions
            {
                PaymentMethodTypes = new List<string> { "card" },
                LineItems = new List<SessionLineItemOptions>
                {
                    new SessionLineItemOptions
                    {
                        PriceData = new SessionLineItemPriceDataOptions
                        {
                            Currency = "bam",
                            UnitAmount = (long)(request.Amount * 100),
                            ProductData = new SessionLineItemPriceDataProductDataOptions
                            {
                                Name = request.Description ?? "Narudžba",
                            },
                        },
                        Quantity = 1,
                    },
                },
                Mode = "payment",
                SuccessUrl = request.SuccessUrl ?? "buildit://payment-success",
                CancelUrl = request.CancelUrl ?? "buildit://payment-cancel",
                Metadata = metadata,
            };

            var service = new SessionService();
            var session = service.Create(options);

            _logger.LogInformation($"✅ CHECKOUT-SESSION: Session kreiran! SessionId={session.Id}, URL={session.Url}");
            
            return Ok(new { sessionId = session.Id, url = session.Url });
        }
        catch (StripeException ex)
        {
            _logger.LogError($"❌ CHECKOUT-SESSION: Stripe greška: {ex.Message}");
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError($"❌ CHECKOUT-SESSION: Opća greška: {ex.Message}");
            _logger.LogError($"❌ CHECKOUT-SESSION: Stack trace: {ex.StackTrace}");
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("verify-payment")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyPayment([FromBody] VerifyPaymentRequest request)
    {
        try
        {
            _logger.LogInformation($"🔵 VERIFY-PAYMENT: Počinje verifikacija za sessionId: {request.SessionId}");
            
            var service = new SessionService();
            var session = service.Get(request.SessionId);

            _logger.LogInformation($"🔵 VERIFY-PAYMENT: Session status: {session.PaymentStatus}, PaymentIntentId: {session.PaymentIntentId}, Status: {session.Status}");

            if (session.PaymentStatus == "paid")
            {
                _logger.LogInformation($"🔵 VERIFY-PAYMENT: Plaćanje je uspješno, provjeravam postojeće narudžbe...");
                
                var existingOrder = _context.Orders
                    .FirstOrDefault(o => o.TransactionId != null && 
                        _context.Transactions.Any(t => t.Id == o.TransactionId && t.StripeTransactionId == session.PaymentIntentId));

                if (existingOrder != null)
                {
                    _logger.LogInformation($"🔵 VERIFY-PAYMENT: Postojeća narudžba pronađena: OrderId={existingOrder.Id}, OrderNumber={existingOrder.OrderNumber}");
                    return Ok(new { 
                        success = true, 
                        paymentIntentId = session.PaymentIntentId,
                        amount = session.AmountTotal / 100.0m,
                        orderId = existingOrder.Id,
                        orderNumber = existingOrder.OrderNumber
                    });
                }

                if (session.Metadata != null && session.Metadata.ContainsKey("userId") && session.Metadata.ContainsKey("cartIds"))
                {
                    _logger.LogInformation($"🔵 VERIFY-PAYMENT: Metadata postoji, userId={session.Metadata["userId"]}, cartIds={session.Metadata["cartIds"]}");
                    
                    try
                    {
                        _logger.LogInformation($"🔵 VERIFY-PAYMENT: Pozivam CreateOrderFromSession...");
                        await CreateOrderFromSession(session);
                        _logger.LogInformation($"🔵 VERIFY-PAYMENT: CreateOrderFromSession završeno, provjeravam novu narudžbu...");
                        
                        var newOrder = _context.Orders
                            .FirstOrDefault(o => o.TransactionId != null && 
                                _context.Transactions.Any(t => t.Id == o.TransactionId && t.StripeTransactionId == session.PaymentIntentId));

                        if (newOrder != null)
                        {
                            _logger.LogInformation($"✅ VERIFY-PAYMENT: Nova narudžba kreirana uspješno! OrderId={newOrder.Id}, OrderNumber={newOrder.OrderNumber}");
                            return Ok(new { 
                                success = true, 
                                paymentIntentId = session.PaymentIntentId,
                                amount = session.AmountTotal / 100.0m,
                                orderId = newOrder.Id,
                                orderNumber = newOrder.OrderNumber
                            });
                        }
                        else
                        {
                            _logger.LogWarning($"⚠️ VERIFY-PAYMENT: CreateOrderFromSession završeno, ali narudžba nije pronađena u bazi!");
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError($"❌ VERIFY-PAYMENT: Greška pri kreiranju narudžbe: {ex.Message}");
                        _logger.LogError($"❌ VERIFY-PAYMENT: Stack trace: {ex.StackTrace}");
                        return BadRequest(new { success = false, message = $"Greška pri kreiranju narudžbe: {ex.Message}" });
                    }
                }
                else
                {
                    _logger.LogWarning($"⚠️ VERIFY-PAYMENT: Metadata ne sadrži potrebne podatke. Metadata je null: {session.Metadata == null}");
                    if (session.Metadata != null)
                    {
                        _logger.LogWarning($"⚠️ VERIFY-PAYMENT: Metadata keys: {string.Join(", ", session.Metadata.Keys)}");
                    }
                }

                return BadRequest(new { success = false, message = "Nedostaju potrebni podaci za kreiranje narudžbe" });
            }
            else if (session.PaymentStatus == "unpaid" || session.PaymentStatus == "no_payment_required")
            {
                _logger.LogInformation($"🔵 VERIFY-PAYMENT: Plaćanje još nije izvršeno. Status: {session.PaymentStatus}");
                return Ok(new { success = false, message = "Plaćanje još nije izvršeno", paymentStatus = session.PaymentStatus });
            }
            else
            {
                _logger.LogWarning($"⚠️ VERIFY-PAYMENT: Plaćanje nije uspješno. Status: {session.PaymentStatus}");
                return Ok(new { success = false, message = $"Plaćanje nije uspješno. Status: {session.PaymentStatus}", paymentStatus = session.PaymentStatus });
            }
        }
        catch (StripeException ex)
        {
            _logger.LogError($"❌ VERIFY-PAYMENT: Stripe greška: {ex.Message}");
            return BadRequest(new { success = false, message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError($"❌ VERIFY-PAYMENT: Opća greška: {ex.Message}");
            _logger.LogError($"❌ VERIFY-PAYMENT: Stack trace: {ex.StackTrace}");
            return BadRequest(new { success = false, message = ex.Message });
        }
    }

    [HttpPost("webhook")]
    [AllowAnonymous]
    public async Task<IActionResult> Webhook()
    {
        var json = await new StreamReader(HttpContext.Request.Body).ReadToEndAsync();
        
        try
        {
            _logger.LogInformation($"🔵 WEBHOOK: Primljen webhook event");
            var stripeEvent = EventUtility.ParseEvent(json);
            _logger.LogInformation($"🔵 WEBHOOK: Event type: {stripeEvent.Type}");
            
            if (stripeEvent.Type == "checkout.session.completed")
            {
                var session = stripeEvent.Data.Object as Session;
                _logger.LogInformation($"🔵 WEBHOOK: CheckoutSessionCompleted, PaymentStatus: {session?.PaymentStatus}");
                
                if (session?.PaymentStatus == "paid" && session.Metadata != null && session.Metadata.ContainsKey("userId"))
                {
                    _logger.LogInformation($"🔵 WEBHOOK: Pozivam CreateOrderFromSession...");
                    await CreateOrderFromSession(session);
                    _logger.LogInformation($"✅ WEBHOOK: CreateOrderFromSession završeno");
                }
            }

            return Ok();
        }
        catch (StripeException ex)
        {
            _logger.LogError($"❌ WEBHOOK: Stripe greška: {ex.Message}");
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError($"❌ WEBHOOK: Opća greška: {ex.Message}");
            _logger.LogError($"❌ WEBHOOK: Stack trace: {ex.StackTrace}");
            return BadRequest(new { message = ex.Message });
        }
    }

    private Task CreateOrderFromSession(Session session)
    {
        _logger.LogInformation($"🔵 CREATE-ORDER: Počinje kreiranje narudžbe iz session-a");
        
        if (session.Metadata == null || !session.Metadata.ContainsKey("userId") || !session.Metadata.ContainsKey("cartIds"))
        {
            _logger.LogError($"❌ CREATE-ORDER: Nedostaju potrebni podaci u session metadata");
            throw new Exception("Nedostaju potrebni podaci u session metadata");
        }

        try
        {
            var userId = int.Parse(session.Metadata["userId"]);
            var cartIds = session.Metadata["cartIds"].Split(',').Select(int.Parse).ToList();
            _logger.LogInformation($"🔵 CREATE-ORDER: userId={userId}, cartIds={string.Join(",", cartIds)}");
            
            int? deliveryProviderId = null;
            if (session.Metadata.ContainsKey("deliveryProviderId") && !string.IsNullOrWhiteSpace(session.Metadata["deliveryProviderId"]))
            {
                if (int.TryParse(session.Metadata["deliveryProviderId"], out int parsedId))
                {
                    var deliveryProviderExists = _context.DeliveryProviders.Any(dp => dp.Id == parsedId);
                    if (deliveryProviderExists)
                    {
                        deliveryProviderId = parsedId;
                        _logger.LogInformation($"🔵 CREATE-ORDER: deliveryProviderId={parsedId} je validan");
                    }
                    else
                    {
                        _logger.LogWarning($"⚠️ CREATE-ORDER: deliveryProviderId={parsedId} ne postoji u bazi, postavljam na null");
                        deliveryProviderId = null;
                    }
                }
                else
                {
                    _logger.LogWarning($"⚠️ CREATE-ORDER: Neuspješno parsiranje deliveryProviderId: {session.Metadata["deliveryProviderId"]}");
                }
            }
            
            var deliveryType = session.Metadata.ContainsKey("deliveryType") && !string.IsNullOrWhiteSpace(session.Metadata["deliveryType"])
                ? session.Metadata["deliveryType"] 
                : null;
            var shippingAddress = session.Metadata.ContainsKey("shippingAddress") && !string.IsNullOrWhiteSpace(session.Metadata["shippingAddress"])
                ? session.Metadata["shippingAddress"] 
                : null;

            _logger.LogInformation($"🔵 CREATE-ORDER: deliveryProviderId={deliveryProviderId ?? (int?)null}, deliveryType={deliveryType ?? "null"}, shippingAddress={shippingAddress ?? "null"}");

            if (session.PaymentIntentId != null)
            {
                var existingOrder = _context.Orders
                    .FirstOrDefault(o => o.TransactionId != null && 
                        _context.Transactions.Any(t => t.Id == o.TransactionId && t.StripeTransactionId == session.PaymentIntentId));

                if (existingOrder != null)
                {
                    _logger.LogInformation($"🔵 CREATE-ORDER: Postojeća narudžba već postoji, preskačem kreiranje");
                    return Task.CompletedTask;
                }
            }

            _logger.LogInformation($"🔵 CREATE-ORDER: Učitavam cart items iz baze...");
            var carts = _context.Carts
                .Include(c => c.Listing)
                .ThenInclude(l => l.Item)
                .Where(c => cartIds.Contains(c.Id) && c.UserId == userId)
                .ToList();

            _logger.LogInformation($"🔵 CREATE-ORDER: Pronađeno {carts.Count} cart items");

            if (!carts.Any())
            {
                _logger.LogWarning($"⚠️ CREATE-ORDER: Nema cart items, prekidam kreiranje narudžbe");
                return Task.CompletedTask;
            }

            foreach (var cart in carts)
            {
                _logger.LogInformation($"🔵 CREATE-ORDER: Cart {cart.Id} - ListingId={cart.ListingId}, Listing.UserId={cart.Listing?.UserId}");
            }

            var subtotal = carts.Sum(c => c.TotalPrice);
            var tax = subtotal * 0.10m;
            var deliveryCost = 0m;
            
            if (deliveryType == "BH Pošta")
                deliveryCost = 5.00m;
            else if (deliveryType == "X Express")
                deliveryCost = 7.00m;
            else if (deliveryType == "EuroExpress")
                deliveryCost = 8.00m;

            var finalAmount = subtotal + tax + deliveryCost;
            _logger.LogInformation($"🔵 CREATE-ORDER: subtotal={subtotal}, tax={tax}, deliveryCost={deliveryCost}, finalAmount={finalAmount}");

            var orderNumber = $"ORD-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString().Substring(0, 8).ToUpper()}";
            _logger.LogInformation($"🔵 CREATE-ORDER: orderNumber={orderNumber}");

            _logger.LogInformation($"🔵 CREATE-ORDER: Kreiranje Transaction-a...");
            var firstCart = carts.First();
            var listing = firstCart.Listing;
            var sellerId = listing?.UserId ?? userId;
            
            var transactionRequest = new BuildIT.Model.Requests.TransactionInsertRequest
            {
                ListingId = firstCart.ListingId,
                BuyerId = userId,
                SellerId = sellerId,
                Amount = finalAmount,
                Type = "Payment",
                Status = "Completed",
                PaymentMethod = "Stripe",
                TransactionDate = DateTime.UtcNow,
                StripeTransactionId = session.PaymentIntentId,
            };

            var transaction = _transactionService.Insert(transactionRequest);
            _logger.LogInformation($"✅ CREATE-ORDER: Transaction kreiran! TransactionId={transaction.Id}, StripeTransactionId={transaction.StripeTransactionId}");

            int? rentalDays = null;
            DateTime? rentalStartDate = null;
            DateTime? rentalEndDate = null;

            var rentalCart = carts.FirstOrDefault(c => c.RentalDays.HasValue && c.RentalDays.Value > 0);
            if (rentalCart != null)
            {
                rentalDays = rentalCart.RentalDays.Value;
                rentalStartDate = DateTime.UtcNow.Date;
                rentalEndDate = rentalStartDate.Value.AddDays(rentalDays.Value - 1);
                _logger.LogInformation($"🔵 CREATE-ORDER: Pronađen rental cart - RentalDays={rentalDays}, StartDate={rentalStartDate}, EndDate={rentalEndDate}");
            }

            _logger.LogInformation($"🔵 CREATE-ORDER: Kreiranje Order-a...");
            var orderRequest = new OrderInsertRequest
            {
                UserId = userId,
                OrderNumber = orderNumber,
                Status = "Pending",
                OrderType = "Purchase",
                TotalAmount = subtotal,
                TaxAmount = tax,
                FinalAmount = finalAmount,
                PaymentMethod = "Stripe",
                PaymentStatus = "Paid",
                ShippingAddress = shippingAddress,
                DeliveryProviderId = deliveryProviderId,
                DeliveryType = deliveryType,
                TransactionId = transaction.Id,
                RentalDays = rentalDays,
                RentalStartDate = rentalStartDate,
                RentalEndDate = rentalEndDate,
            };

            var order = _orderService.Insert(orderRequest);
            _logger.LogInformation($"✅ CREATE-ORDER: Order kreiran! OrderId={order.Id}, OrderNumber={order.OrderNumber}");

            _logger.LogInformation($"🔵 CREATE-ORDER: Slanje notifikacije prodavcu preko RabbitMQ...");
            _logger.LogInformation($"🔵 CREATE-ORDER: SellerId={sellerId}, OrderId={order.Id}, OrderNumber={order.OrderNumber}, Amount={finalAmount}");
            
            if (sellerId <= 0)
            {
                _logger.LogWarning($"⚠️ CREATE-ORDER: SellerId je {sellerId}, što nije validno! Listing.UserId={listing?.UserId}, BuyerId={userId}");
            }
            
            try
            {
                _logger.LogInformation($"🔵 CREATE-ORDER: Pozivam _rabbitMQService.PublishOrderNotification...");
                _rabbitMQService.PublishOrderNotification(sellerId, order.Id, order.OrderNumber, finalAmount);
                _logger.LogInformation($"✅ CREATE-ORDER: _rabbitMQService.PublishOrderNotification završio! (SellerId={sellerId})");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"❌ CREATE-ORDER: Greška pri slanju notifikacije prodavcu - Exception: {ex.Message}");
                _logger.LogError($"❌ CREATE-ORDER: Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ CREATE-ORDER: Inner exception: {ex.InnerException.Message}");
                }
            }

            _logger.LogInformation($"🔵 CREATE-ORDER: Provjeravam uslove za kreiranje in-app notifikacije... sellerId={sellerId}, userId={userId}, listing != null: {listing != null}");
            
            if (sellerId > 0 && sellerId != userId && listing != null)
            {
                try
                {
                    _logger.LogInformation($"🔵 CREATE-ORDER: Uslovi zadovoljeni! Kreiranje in-app notifikacije za prodavca (SellerId={sellerId})...");
                    
                    var buyer = _context.Users.FirstOrDefault(u => u.Id == userId);
                    var listingTitle = listing.Title ?? "Nepoznat artikal";
                    var buyerName = buyer != null ? $"{buyer.FirstName} {buyer.LastName}".Trim() : "Kupac";

                    _logger.LogInformation($"🔵 CREATE-ORDER: BuyerName={buyerName}, ListingTitle={listingTitle}, FinalAmount={finalAmount}, OrderNumber={orderNumber}");

                    var notificationRequest = new NotificationInsertRequest
                    {
                        UserId = sellerId,
                        Title = "🎉 Vaš artikal je kupljen!",
                        Message = $"Korisnik {buyerName} je kupio vaš artikal \"{listingTitle}\" za {finalAmount:C}. Broj narudžbe: {orderNumber}",
                        NotificationType = "Order",
                        ReferenceId = order.Id,
                        Priority = "High",
                        IsRead = false,
                        IsSent = true
                    };

                    _logger.LogInformation($"🔵 CREATE-ORDER: Pozivam _notificationService.Insert... UserId={sellerId}, NotificationType=Order, ReferenceId={order.Id}");
                    var notification = _notificationService.Insert(notificationRequest);
                    _logger.LogInformation($"✅ CREATE-ORDER: In-app notifikacija kreirana! NotificationId={notification.Id}, SellerId={sellerId}");
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"❌ CREATE-ORDER: Greška pri kreiranju in-app notifikacije: {ex.Message}");
                    _logger.LogError($"❌ CREATE-ORDER: Stack trace: {ex.StackTrace}");
                    if (ex.InnerException != null)
                    {
                        _logger.LogError($"❌ CREATE-ORDER: Inner exception: {ex.InnerException.Message}");
                    }
                }
            }
            else
            {
                if (sellerId <= 0)
                {
                    _logger.LogWarning($"⚠️ CREATE-ORDER: sellerId ({sellerId}) <= 0, preskačem kreiranje notifikacije");
                }
                if (sellerId == userId)
                {
                    _logger.LogInformation($"🔵 CREATE-ORDER: sellerId ({sellerId}) == userId ({userId}), preskačem kreiranje notifikacije (korisnik kupuje svoj artikal)");
                }
                if (listing == null)
                {
                    _logger.LogWarning($"⚠️ CREATE-ORDER: listing je null, preskačem kreiranje notifikacije");
                }
            }

            foreach (var cart in carts)
            {
                if (cart.Listing != null)
                {
                    var cartSellerId = cart.Listing.UserId;
                    _logger.LogInformation($"🔵 CREATE-ORDER: Cart {cart.Id} - SellerId={cartSellerId}, ListingId={cart.ListingId}, ListingTitle={cart.Listing.Title}");
                    
                    if (cartSellerId > 0 && cartSellerId != userId && cartSellerId != sellerId)
                    {
                        try
                        {
                            _logger.LogInformation($"🔵 CREATE-ORDER: Kreiranje dodatne in-app notifikacije za prodavca (SellerId={cartSellerId}) za Cart {cart.Id}...");
                            
                            var buyer = _context.Users.FirstOrDefault(u => u.Id == userId);
                            var listingTitle = cart.Listing.Title ?? "Nepoznat artikal";
                            var buyerName = buyer != null ? $"{buyer.FirstName} {buyer.LastName}".Trim() : "Kupac";
                            var cartAmount = cart.TotalPrice;

                            var notificationRequest = new NotificationInsertRequest
                            {
                                UserId = cartSellerId,
                                Title = "🎉 Vaš artikal je kupljen!",
                                Message = $"Korisnik {buyerName} je kupio vaš artikal \"{listingTitle}\" za {cartAmount:C}. Broj narudžbe: {orderNumber}",
                                NotificationType = "Order",
                                ReferenceId = order.Id,
                                Priority = "High",
                                IsRead = false,
                                IsSent = true
                            };

                            var notification = _notificationService.Insert(notificationRequest);
                            _logger.LogInformation($"✅ CREATE-ORDER: Dodatna in-app notifikacija kreirana! NotificationId={notification.Id}, SellerId={cartSellerId}");
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"❌ CREATE-ORDER: Greška pri kreiranju dodatne in-app notifikacije za Cart {cart.Id}: {ex.Message}");
                        }
                    }
                }
            }

            _logger.LogInformation($"🔵 CREATE-ORDER: Brisanje cart items...");
            foreach (var cart in carts)
            {
                _cartService.DeleteCartItem(cart.Id);
                _logger.LogInformation($"🔵 CREATE-ORDER: Cart item {cart.Id} obrisan");
            }

            _logger.LogInformation($"✅ CREATE-ORDER: Sve završeno uspješno! OrderId={order.Id}");
            return Task.CompletedTask;
        }
        catch (Exception ex)
        {
            _logger.LogError($"❌ CREATE-ORDER: Greška: {ex.Message}");
            _logger.LogError($"❌ CREATE-ORDER: Stack trace: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                _logger.LogError($"❌ CREATE-ORDER: Inner exception: {ex.InnerException.Message}");
            }
            return Task.FromException(new Exception($"Greška pri kreiranju narudžbe: {ex.Message}"));
        }
    }
}


