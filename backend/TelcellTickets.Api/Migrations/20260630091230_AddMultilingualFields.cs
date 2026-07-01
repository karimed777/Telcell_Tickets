using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TelcellTickets.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMultilingualFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AddressAm",
                table: "Venues",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "NameAm",
                table: "Venues",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "NameAm",
                table: "TicketTypes",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "DescriptionAm",
                table: "Events",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "TitleAm",
                table: "Events",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AddressAm",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "NameAm",
                table: "Venues");

            migrationBuilder.DropColumn(
                name: "NameAm",
                table: "TicketTypes");

            migrationBuilder.DropColumn(
                name: "DescriptionAm",
                table: "Events");

            migrationBuilder.DropColumn(
                name: "TitleAm",
                table: "Events");
        }
    }
}
