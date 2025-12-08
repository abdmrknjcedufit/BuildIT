using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddImagesToItemAndRentalDaysToListing : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MaxRentalDays",
                table: "Listings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "MinRentalDays",
                table: "Listings",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Images",
                table: "Items",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "MaxRentalDays",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "MinRentalDays",
                table: "Listings");

            migrationBuilder.DropColumn(
                name: "Images",
                table: "Items");
        }
    }
}
