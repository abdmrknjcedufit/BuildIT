using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Database;

public partial class BuildITDbContext : DbContext
{
    public BuildITDbContext()
    {
    }

    public BuildITDbContext(DbContextOptions<BuildITDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<User> Users { get; set; }
    public virtual DbSet<Role> Roles { get; set; }
    public virtual DbSet<UserRole> UserRoles { get; set; }
    public virtual DbSet<Company> Companies { get; set; }
    public virtual DbSet<City> Cities { get; set; }
    public virtual DbSet<Category> Categories { get; set; }
    public virtual DbSet<Subcategory> Subcategories { get; set; }
    public virtual DbSet<Item> Items { get; set; }
    public virtual DbSet<Listing> Listings { get; set; }
    public virtual DbSet<Transaction> Transactions { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.HasIndex(e => e.Email).IsUnique();
            entity.HasIndex(e => e.Username).IsUnique();

            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.FirstName).HasMaxLength(50);
            entity.Property(e => e.LastName).HasMaxLength(50);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.UserType).HasMaxLength(50).HasDefaultValue("Individual");
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(50).IsRequired();
        });

        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.HasKey(e => e.Id);

            entity.HasOne(e => e.User)
                .WithMany(u => u.UserRoles)
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(e => e.Role)
                .WithMany(r => r.UserRoles)
                .HasForeignKey(e => e.RoleId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<City>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(100).IsRequired();
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Description).HasMaxLength(200).IsRequired();
        });

        modelBuilder.Entity<Subcategory>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Description).HasMaxLength(200).IsRequired();

            entity.HasOne(e => e.Category)
                .WithMany(c => c.Subcategories)
                .HasForeignKey(e => e.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Company>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(200).IsRequired();
            entity.Property(e => e.PIB).HasMaxLength(20);
            entity.Property(e => e.Address).HasMaxLength(500);
            entity.Property(e => e.Phone).HasMaxLength(20);
            entity.Property(e => e.Email).HasMaxLength(100);
            entity.Property(e => e.CityId);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.City)
                .WithMany(c => c.Companies)
                .HasForeignKey(e => e.CityId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Item>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.Price).HasColumnType("decimal(18,2)");
            entity.Property(e => e.ItemType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Available");
            entity.Property(e => e.Condition).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Brand).HasMaxLength(100);
            entity.Property(e => e.Model).HasMaxLength(100);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(e => e.Company)
                .WithMany(c => c.Items)
                .HasForeignKey(e => e.CompanyId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(e => e.Category)
                .WithMany(c => c.Items)
                .HasForeignKey(e => e.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<Listing>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).HasMaxLength(200).IsRequired();
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.ListingType).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Status).HasMaxLength(50).HasDefaultValue("Active");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.UpdatedAt)
                .HasColumnType("datetime");
            entity.Property(e => e.Images).HasMaxLength(2000);

            entity.HasOne(e => e.Item)
                .WithMany()
                .HasForeignKey(e => e.ItemId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.User)
                .WithMany()
                .HasForeignKey(e => e.UserId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.City)
                .WithMany()
                .HasForeignKey(e => e.CityId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Transaction>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Amount).HasColumnType("decimal(18,2)");
            entity.Property(e => e.Status).HasMaxLength(50).IsRequired();
            entity.Property(e => e.PaymentMethod).HasMaxLength(50).IsRequired();
            entity.Property(e => e.Type).HasMaxLength(50).IsRequired();
            entity.Property(e => e.TransactionDate).HasColumnType("datetime");
            entity.Property(e => e.StripeTransactionId).HasMaxLength(50);
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(e => e.Listing)
                .WithMany()
                .HasForeignKey(e => e.ListingId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Buyer)
                .WithMany()
                .HasForeignKey(e => e.BuyerId)
                .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(e => e.Seller)
                .WithMany()
                .HasForeignKey(e => e.SellerId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}

