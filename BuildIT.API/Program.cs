using BuildIT.API;
using BuildIT.API.Filters;
using BuildIT.Services.Hubs;
using BuildIT.Services.Database;
using BuildIT.Services.Interfaces;
using BuildIT.Services.Services;
using Mapster;
using MapsterMapper;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using BuildIT.Model.Requests;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddHttpContextAccessor();

builder.Services.AddTransient<IUserService, UserService>();
builder.Services.AddTransient<ICompanyService, CompanyService>();
builder.Services.AddTransient<IItemService, ItemService>();
builder.Services.AddTransient<ICategoryService, CategoryService>();
builder.Services.AddTransient<ISubcategoryService, SubcategoryService>();
builder.Services.AddTransient<IListingService, ListingService>();
builder.Services.AddTransient<ICityService, CityService>();
builder.Services.AddTransient<ITransactionService, TransactionService>();
builder.Services.AddTransient<IReviewService, ReviewService>();
builder.Services.AddTransient<INotificationService, NotificationService>();
builder.Services.AddTransient<IComplaintService, ComplaintService>();
builder.Services.AddTransient<IOrderService, OrderService>();
builder.Services.AddTransient<IAuditLogService, AuditLogService>();
builder.Services.AddTransient<IDashboardService, DashboardService>();
builder.Services.AddTransient<ICartService, CartService>();
builder.Services.AddTransient<IConversationService, ConversationService>();
builder.Services.AddTransient<IMessageService, MessageService>();
builder.Services.AddTransient<IDeliveryProviderService, DeliveryProviderService>();
builder.Services.AddTransient<IEmailService, EmailService>();
builder.Services.AddTransient<ISmsService, SmsService>();
builder.Services.AddSingleton<IRabbitMQService, RabbitMQService>();
builder.Services.AddTransient<IFavoriteService, FavoriteService>();
builder.Services.AddTransient<IRecommenderService, RecommenderService>();
builder.Services.AddHostedService<OrderNotificationService>();

builder.Services.AddScoped<AuditLogActionFilter>();

builder.Services.AddSignalR();

builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
    x.Filters.Add<AuthorizationFilter>();
    x.Filters.Add<AuditLogActionFilter>();
})
.AddJsonOptions(options =>
{
    options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    options.JsonSerializerOptions.WriteIndented = true;
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.AddSecurityDefinition("basicAuth", new OpenApiSecurityScheme()
    {
        Type = SecuritySchemeType.Http,
        Scheme = "basic"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference{Type = ReferenceType.SecurityScheme, Id = "basicAuth"}
            },
            new string[]{}
        }
    });

    c.OperationFilter<BuildIT.API.Filters.SwaggerOperationFilter>();
});

var connectionString = builder.Configuration.GetConnectionString("BuildITDB") 
    ?? throw new InvalidOperationException("Connection string 'BuildITDB' not found.");

builder.Services.AddDbContext<BuildITDbContext>(options =>
    options.UseSqlServer(connectionString, b => b.MigrationsAssembly("BuildIT.API")));

builder.Services.AddMapster();

TypeAdapterConfig<BuildIT.Services.Database.User, BuildIT.Model.Models.User>.NewConfig()
    .Map(dest => dest.Roles, src => src.UserRoles.Select(ur => ur.Role.Name).ToList());

TypeAdapterConfig<UserUpdateRequest, BuildIT.Services.Database.User>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<CompanyInsertRequest, BuildIT.Services.Database.Company>
    .NewConfig();

TypeAdapterConfig<CompanyUpdateRequest, BuildIT.Services.Database.Company>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Company, BuildIT.Model.Models.Company>
    .NewConfig();

TypeAdapterConfig<ItemInsertRequest, BuildIT.Services.Database.Item>
    .NewConfig();

TypeAdapterConfig<ItemUpdateRequest, BuildIT.Services.Database.Item>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Item, BuildIT.Model.Models.Item>
    .NewConfig();

TypeAdapterConfig<CategoryInsertRequest, BuildIT.Services.Database.Category>
    .NewConfig();

TypeAdapterConfig<CategoryUpdateRequest, BuildIT.Services.Database.Category>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Category, BuildIT.Model.Models.Category>
    .NewConfig();

TypeAdapterConfig<SubcategoryInsertRequest, BuildIT.Services.Database.Subcategory>
    .NewConfig();

TypeAdapterConfig<SubcategoryUpdateRequest, BuildIT.Services.Database.Subcategory>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Subcategory, BuildIT.Model.Models.Subcategory>
    .NewConfig();

TypeAdapterConfig<ListingInsertRequest, BuildIT.Services.Database.Listing>
    .NewConfig();

TypeAdapterConfig<ListingUpdateRequest, BuildIT.Services.Database.Listing>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Listing, BuildIT.Model.Models.Listing>
    .NewConfig();

TypeAdapterConfig<CityInsertRequest, BuildIT.Services.Database.City>
    .NewConfig();

TypeAdapterConfig<CityUpdateRequest, BuildIT.Services.Database.City>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.City, BuildIT.Model.Models.City>
    .NewConfig();

TypeAdapterConfig<TransactionInsertRequest, BuildIT.Services.Database.Transaction>
    .NewConfig();

TypeAdapterConfig<TransactionUpdateRequest, BuildIT.Services.Database.Transaction>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Transaction, BuildIT.Model.Models.Transaction>
    .NewConfig();

TypeAdapterConfig<ReviewInsertRequest, BuildIT.Services.Database.Review>
    .NewConfig();

TypeAdapterConfig<ReviewUpdateRequest, BuildIT.Services.Database.Review>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Review, BuildIT.Model.Models.Review>
    .NewConfig();

TypeAdapterConfig<NotificationInsertRequest, BuildIT.Services.Database.Notification>
    .NewConfig();

TypeAdapterConfig<NotificationUpdateRequest, BuildIT.Services.Database.Notification>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Notification, BuildIT.Model.Models.Notification>
    .NewConfig();

TypeAdapterConfig<ComplaintInsertRequest, BuildIT.Services.Database.Complaint>
    .NewConfig();

TypeAdapterConfig<ComplaintUpdateRequest, BuildIT.Services.Database.Complaint>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Complaint, BuildIT.Model.Models.Complaint>
    .NewConfig();

TypeAdapterConfig<OrderInsertRequest, BuildIT.Services.Database.Order>
    .NewConfig();

TypeAdapterConfig<OrderUpdateRequest, BuildIT.Services.Database.Order>
    .NewConfig()
    .IgnoreNullValues(true);

TypeAdapterConfig<BuildIT.Services.Database.Order, BuildIT.Model.Models.Order>
    .NewConfig();

TypeAdapterConfig<BuildIT.Services.Database.AuditLog, BuildIT.Model.Models.AuditLog>
    .NewConfig();

builder.Services.AddAuthentication("BasicAuthentication")
    .AddScheme<AuthenticationSchemeOptions, BasicAuthenticationHandler>("BasicAuthentication", null);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors(
    options => options
        .SetIsOriginAllowed(x => _ = true)
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials()
);

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<BuildIT.Services.Hubs.ChatHub>("/chathub");

using (var scope = app.Services.CreateScope())
{
    try
    {
        var dataContext = scope.ServiceProvider.GetRequiredService<BuildITDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        var dbConnectionString = connectionString;
        
        logger.LogInformation("Checking database connection and applying migrations...");
        
        if (string.IsNullOrEmpty(dbConnectionString))
        {
            logger.LogError("Connection string 'BuildITDB' is null or empty!");
            return;
        }
        
        // Extract database name from connection string
        var databaseName = dbConnectionString
            .Split(';')
            .FirstOrDefault(s => s.TrimStart().StartsWith("Database=", StringComparison.OrdinalIgnoreCase) || 
                                 s.TrimStart().StartsWith("Initial Catalog=", StringComparison.OrdinalIgnoreCase))?
            .Split('=')[1]
            .Trim();
        
        if (string.IsNullOrEmpty(databaseName))
        {
            logger.LogWarning("Could not extract database name from connection string. Attempting direct connection...");
        }
        else
        {
            logger.LogInformation($"Target database: {databaseName}");
            
            // Create master connection string
            var masterConnectionString = dbConnectionString
                .Replace($"Database={databaseName};", "Database=master;", StringComparison.OrdinalIgnoreCase)
                .Replace($"Initial Catalog={databaseName};", "Initial Catalog=master;", StringComparison.OrdinalIgnoreCase)
                .Replace($"Database={databaseName}", "Database=master", StringComparison.OrdinalIgnoreCase)
                .Replace($"Initial Catalog={databaseName}", "Initial Catalog=master", StringComparison.OrdinalIgnoreCase);
            
            // Try to connect to master and create database if needed
            using (var masterContext = new BuildITDbContext(
                new DbContextOptionsBuilder<BuildITDbContext>()
                    .UseSqlServer(masterConnectionString)
                    .Options))
            {
                var maxRetries = 10;
                var retryDelay = TimeSpan.FromSeconds(5);
                
                for (int i = 0; i < maxRetries; i++)
                {
                    try
                    {
                        if (masterContext.Database.CanConnect())
                        {
                            logger.LogInformation("Successfully connected to SQL Server.");
                            
                            // Check if database exists - databaseName comes from our config, not user input, so safe to use
                            var escapedDbName = databaseName.Replace("'", "''").Replace("]", "]]");
#pragma warning disable EF1002 // SQL injection warning - databaseName is from our config, not user input
                            var dbExistsQuery = $"SELECT COUNT(*) FROM sys.databases WHERE name = '{escapedDbName}'";
                            var dbExistsResult = masterContext.Database.SqlQueryRaw<int>(dbExistsQuery).ToList();
                            var dbExists = dbExistsResult.FirstOrDefault() > 0;
#pragma warning restore EF1002
                            
                            if (!dbExists)
                            {
                                logger.LogInformation($"Database '{databaseName}' does not exist. Creating it...");
                                // Escape brackets for SQL identifier
                                var createDbQuery = $"CREATE DATABASE [{databaseName.Replace("]", "]]")}]";
#pragma warning disable EF1002 // SQL injection warning - databaseName is from our config, not user input
                                masterContext.Database.ExecuteSqlRaw(createDbQuery);
#pragma warning restore EF1002
                                logger.LogInformation($"Database '{databaseName}' created successfully.");
                                
                                // Wait a bit for database to be ready
                                Task.Delay(2000).Wait();
                            }
                            else
                            {
                                logger.LogInformation($"Database '{databaseName}' already exists.");
                            }
                            break;
                        }
                    }
                    catch (Exception ex) when (i < maxRetries - 1)
                    {
                        logger.LogWarning($"Attempt {i + 1}/{maxRetries} failed: {ex.Message}. Retrying in {retryDelay.TotalSeconds} seconds...");
                        Task.Delay(retryDelay).Wait();
                    }
                }
            }
        }
        
        // Now try to connect to the actual database and apply migrations
        var maxDbRetries = 10;
        var dbRetryDelay = TimeSpan.FromSeconds(3);
        bool migrationsApplied = false;
        bool dataSeeded = false;
        
        for (int i = 0; i < maxDbRetries; i++)
        {
            try
            {
                if (dataContext.Database.CanConnect())
                {
                    logger.LogInformation("✅ Database connection successful.");
                    
                    // Apply migrations
                    if (!migrationsApplied)
                    {
                        logger.LogInformation("📦 Applying database migrations...");
                        var pendingMigrations = dataContext.Database.GetPendingMigrations().ToList();
                        if (pendingMigrations.Any())
                        {
                            logger.LogInformation($"Found {pendingMigrations.Count} pending migration(s): {string.Join(", ", pendingMigrations)}");
                            dataContext.Database.Migrate();
                            logger.LogInformation("✅ All database migrations applied successfully.");
                        }
                        else
                        {
                            logger.LogInformation("✅ Database is up to date. No pending migrations.");
                        }
                        migrationsApplied = true;
                    }
                    
                    // Seed initial data
                    if (!dataSeeded)
                    {
                        logger.LogInformation("🌱 Seeding initial data...");
                        SeedData(dataContext, logger);
                        logger.LogInformation("✅ Initial data seeding completed.");
                        dataSeeded = true;
                    }
                    
                    break;
                }
            }
            catch (Exception ex) when (i < maxDbRetries - 1)
            {
                logger.LogWarning($"⚠️ Database connection attempt {i + 1}/{maxDbRetries} failed: {ex.Message}. Retrying in {dbRetryDelay.TotalSeconds} seconds...");
                Task.Delay(dbRetryDelay).Wait();
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "❌ Error connecting to database: {Message}", ex.Message);
                throw;
            }
        }
        
        if (!migrationsApplied || !dataSeeded)
        {
            logger.LogError("❌ Failed to apply migrations or seed data after all retry attempts.");
        }
    }
    catch (Exception ex)
    {
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "Error connecting to database: {Message}", ex.Message);
        logger.LogWarning("Application will continue, but database operations will fail until connection is established.");
    }
}

app.Run();

static void SeedData(BuildITDbContext context, ILogger logger)
{
    try
    {
        logger.LogInformation("🔍 Checking for existing data...");
        
        if (!context.Roles.Any())
        {
            logger.LogInformation("➕ Seeding roles (Admin, User)...");
            context.Roles.AddRange(
                new BuildIT.Services.Database.Role { Name = "Admin" },
                new BuildIT.Services.Database.Role { Name = "User" }
            );
            context.SaveChanges();
            logger.LogInformation("✅ Roles seeded successfully.");
        }
        else
        {
            logger.LogInformation("ℹ️ Roles already exist. Skipping role seeding.");
        }

        var adminRole = context.Roles.FirstOrDefault(r => r.Name == "Admin");
        var userRole = context.Roles.FirstOrDefault(r => r.Name == "User");

        // Seed admin user
        if (adminRole != null && !context.Users.Any(u => u.Username == "admin"))
        {
            logger.LogInformation("➕ Seeding admin user (username: admin, password: test)...");
            var adminSalt = BuildIT.Services.Helpers.HashGenerator.GenerateSalt();
            var adminUser = new BuildIT.Services.Database.User
            {
                FirstName = "Admin",
                LastName = "User",
                Username = "admin",
                Email = "admin@buildit.com",
                Phone = "123456789",
                PasswordHash = BuildIT.Services.Helpers.HashGenerator.GenerateHash(adminSalt, "test"),
                PasswordSalt = adminSalt,
                BirthDate = new DateOnly(1990, 1, 1),
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UserRoles = new List<BuildIT.Services.Database.UserRole>
                {
                    new BuildIT.Services.Database.UserRole { RoleId = adminRole.Id }
                }
            };
            context.Users.Add(adminUser);
            context.SaveChanges();
            logger.LogInformation("✅ Admin user seeded successfully (username: admin, password: test).");
        }
        else if (context.Users.Any(u => u.Username == "admin"))
        {
            logger.LogInformation("ℹ️ Admin user already exists. Skipping.");
        }

        // Seed user1
        if (userRole != null && !context.Users.Any(u => u.Username == "user1"))
        {
            logger.LogInformation("➕ Seeding user1 (username: user1, password: test)...");
            var user1Salt = BuildIT.Services.Helpers.HashGenerator.GenerateSalt();
            var user1 = new BuildIT.Services.Database.User
            {
                FirstName = "User",
                LastName = "One",
                Username = "user1",
                Email = "user1@buildit.com",
                Phone = "111111111",
                PasswordHash = BuildIT.Services.Helpers.HashGenerator.GenerateHash(user1Salt, "test"),
                PasswordSalt = user1Salt,
                BirthDate = new DateOnly(1995, 5, 15),
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UserRoles = new List<BuildIT.Services.Database.UserRole>
                {
                    new BuildIT.Services.Database.UserRole { RoleId = userRole.Id }
                }
            };
            context.Users.Add(user1);
            context.SaveChanges();
            logger.LogInformation("✅ User1 seeded successfully (username: user1, password: test).");
        }
        else if (context.Users.Any(u => u.Username == "user1"))
        {
            logger.LogInformation("ℹ️ User1 already exists. Skipping.");
        }

        // Seed user2
        if (userRole != null && !context.Users.Any(u => u.Username == "user2"))
        {
            logger.LogInformation("➕ Seeding user2 (username: user2, password: test)...");
            var user2Salt = BuildIT.Services.Helpers.HashGenerator.GenerateSalt();
            var user2 = new BuildIT.Services.Database.User
            {
                FirstName = "User",
                LastName = "Two",
                Username = "user2",
                Email = "user2@buildit.com",
                Phone = "222222222",
                PasswordHash = BuildIT.Services.Helpers.HashGenerator.GenerateHash(user2Salt, "test"),
                PasswordSalt = user2Salt,
                BirthDate = new DateOnly(1996, 6, 20),
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UserRoles = new List<BuildIT.Services.Database.UserRole>
                {
                    new BuildIT.Services.Database.UserRole { RoleId = userRole.Id }
                }
            };
            context.Users.Add(user2);
            context.SaveChanges();
            logger.LogInformation("✅ User2 seeded successfully (username: user2, password: test).");
        }
        else if (context.Users.Any(u => u.Username == "user2"))
        {
            logger.LogInformation("ℹ️ User2 already exists. Skipping.");
        }

        // Seed cities
        if (!context.Cities.Any(c => c.Name == "Sarajevo"))
        {
            logger.LogInformation("➕ Seeding city: Sarajevo...");
            context.Cities.Add(new BuildIT.Services.Database.City
            {
                Name = "Sarajevo",
                IsActive = true
            });
            context.SaveChanges();
            logger.LogInformation("✅ City 'Sarajevo' seeded successfully.");
        }
        else
        {
            logger.LogInformation("ℹ️ City 'Sarajevo' already exists. Skipping.");
        }

        if (!context.Cities.Any(c => c.Name == "Mostar"))
        {
            logger.LogInformation("➕ Seeding city: Mostar...");
            context.Cities.Add(new BuildIT.Services.Database.City
            {
                Name = "Mostar",
                IsActive = true
            });
            context.SaveChanges();
            logger.LogInformation("✅ City 'Mostar' seeded successfully.");
        }
        else
        {
            logger.LogInformation("ℹ️ City 'Mostar' already exists. Skipping.");
        }

        logger.LogInformation("✅ Data seeding process completed.");
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "❌ Error seeding data: {Message}", ex.Message);
        throw; // Re-throw to ensure we know if seeding failed
    }
}

TypeAdapterConfig<FavoriteInsertRequest, BuildIT.Services.Database.Favorite>
    .NewConfig();

TypeAdapterConfig<BuildIT.Services.Database.Favorite, BuildIT.Model.Models.Favorite>
    .NewConfig();

