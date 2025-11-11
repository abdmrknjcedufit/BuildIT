using BuildIT;
using BuildIT.Filters;
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

builder.Services.AddScoped<AuditLogActionFilter>();

builder.Services.AddControllers(x =>
{
    x.Filters.Add<ExceptionFilter>();
    x.Filters.Add<AuthorizationFilter>();
    x.Filters.Add<AuditLogActionFilter>();
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

    c.OperationFilter<BuildIT.Filters.SwaggerOperationFilter>();
});

var connectionString = builder.Configuration.GetConnectionString("BuildITDB") 
    ?? throw new InvalidOperationException("Connection string 'BuildITDB' not found.");

builder.Services.AddDbContext<BuildITDbContext>(options =>
    options.UseSqlServer(connectionString));

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

using (var scope = app.Services.CreateScope())
{
    try
    {
        var dataContext = scope.ServiceProvider.GetRequiredService<BuildITDbContext>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();
        
        logger.LogInformation("Checking database connection and applying migrations...");
        
        if (dataContext.Database.CanConnect())
        {
            logger.LogInformation("Database connection successful. Applying migrations...");
            dataContext.Database.Migrate();
            logger.LogInformation("Database migrations applied successfully.");
            
            SeedData(dataContext, logger);
        }
        else
        {
            logger.LogWarning("Cannot connect to database. Please check your connection string and ensure SQL Server is running.");
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
        if (!context.Roles.Any())
        {
            logger.LogInformation("Seeding roles...");
            context.Roles.AddRange(
                new BuildIT.Services.Database.Role { Name = "Admin" },
                new BuildIT.Services.Database.Role { Name = "User" }
            );
            context.SaveChanges();
            logger.LogInformation("Roles seeded successfully.");
        }

        var adminRole = context.Roles.FirstOrDefault(r => r.Name == "Admin");
        var userRole = context.Roles.FirstOrDefault(r => r.Name == "User");

        if (adminRole != null && !context.Users.Any(u => u.Username == "desktop"))
        {
            logger.LogInformation("Seeding desktop admin user...");
            var adminSalt = BuildIT.Services.Helpers.HashGenerator.GenerateSalt();
            var adminUser = new BuildIT.Services.Database.User
            {
                FirstName = "Admin",
                LastName = "User",
                Username = "desktop",
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
            logger.LogInformation("Desktop admin user seeded (username: desktop, password: test).");
        }

        if (userRole != null && !context.Users.Any(u => u.Username == "mobile"))
        {
            logger.LogInformation("Seeding mobile user...");
            var userSalt = BuildIT.Services.Helpers.HashGenerator.GenerateSalt();
            var mobileUser = new BuildIT.Services.Database.User
            {
                FirstName = "Mobile",
                LastName = "User",
                Username = "mobile",
                Email = "mobile@buildit.com",
                Phone = "987654321",
                PasswordHash = BuildIT.Services.Helpers.HashGenerator.GenerateHash(userSalt, "test"),
                PasswordSalt = userSalt,
                BirthDate = new DateOnly(1995, 5, 15),
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UserRoles = new List<BuildIT.Services.Database.UserRole>
                {
                    new BuildIT.Services.Database.UserRole { RoleId = userRole.Id }
                }
            };
            context.Users.Add(mobileUser);
            context.SaveChanges();
            logger.LogInformation("Mobile user seeded (username: mobile, password: test).");
        }

    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error seeding data: {Message}", ex.Message);
    }
}
