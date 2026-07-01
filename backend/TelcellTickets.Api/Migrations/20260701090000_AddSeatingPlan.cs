using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TelcellTickets.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSeatingPlan : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ── Шаблоны залов ──────────────────────────────────────────
            migrationBuilder.CreateTable(
                name: "VenueLayouts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VenueId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VenueLayouts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VenueLayouts_Venues_VenueId",
                        column: x => x.VenueId,
                        principalTable: "Venues",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "VenueFloors",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VenueLayoutId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_VenueFloors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_VenueFloors_VenueLayouts_VenueLayoutId",
                        column: x => x.VenueLayoutId,
                        principalTable: "VenueLayouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "SeatBlocks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VenueFloorId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeatType = table.Column<string>(type: "text", nullable: false),
                    DefaultPrice = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    DefaultDescription = table.Column<string>(type: "text", nullable: true),
                    DefaultColor = table.Column<string>(type: "text", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    RotationDeg = table.Column<double>(type: "double precision", nullable: false),
                    Rows = table.Column<int>(type: "integer", nullable: false),
                    SeatsPerRow = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SeatBlocks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SeatBlocks_VenueFloors_VenueFloorId",
                        column: x => x.VenueFloorId,
                        principalTable: "VenueFloors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Seats",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SeatBlockId = table.Column<Guid>(type: "uuid", nullable: false),
                    Row = table.Column<int>(type: "integer", nullable: false),
                    Number = table.Column<int>(type: "integer", nullable: false),
                    SeatType = table.Column<string>(type: "text", nullable: false),
                    Price = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Color = table.Column<string>(type: "text", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Seats", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Seats_SeatBlocks_SeatBlockId",
                        column: x => x.SeatBlockId,
                        principalTable: "SeatBlocks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "Stages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    VenueFloorId = table.Column<Guid>(type: "uuid", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    Width = table.Column<double>(type: "double precision", nullable: false),
                    Height = table.Column<double>(type: "double precision", nullable: false),
                    Label = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Stages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Stages_VenueFloors_VenueFloorId",
                        column: x => x.VenueFloorId,
                        principalTable: "VenueFloors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // ── Схема события (копия) ──────────────────────────────────
            migrationBuilder.CreateTable(
                name: "EventLayouts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventId = table.Column<Guid>(type: "uuid", nullable: false),
                    VenueLayoutId = table.Column<Guid>(type: "uuid", nullable: true),
                    HasSeatingPlan = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventLayouts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventLayouts_Events_EventId",
                        column: x => x.EventId,
                        principalTable: "Events",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_EventLayouts_VenueLayouts_VenueLayoutId",
                        column: x => x.VenueLayoutId,
                        principalTable: "VenueLayouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "EventFloors",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventLayoutId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Order = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventFloors", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventFloors_EventLayouts_EventLayoutId",
                        column: x => x.EventLayoutId,
                        principalTable: "EventLayouts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EventSeatBlocks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventFloorId = table.Column<Guid>(type: "uuid", nullable: false),
                    SeatType = table.Column<string>(type: "text", nullable: false),
                    DefaultPrice = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    DefaultDescription = table.Column<string>(type: "text", nullable: true),
                    DefaultColor = table.Column<string>(type: "text", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    RotationDeg = table.Column<double>(type: "double precision", nullable: false),
                    Rows = table.Column<int>(type: "integer", nullable: false),
                    SeatsPerRow = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventSeatBlocks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventSeatBlocks_EventFloors_EventFloorId",
                        column: x => x.EventFloorId,
                        principalTable: "EventFloors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EventSeats",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventSeatBlockId = table.Column<Guid>(type: "uuid", nullable: false),
                    Row = table.Column<int>(type: "integer", nullable: false),
                    Number = table.Column<int>(type: "integer", nullable: false),
                    SeatType = table.Column<string>(type: "text", nullable: false),
                    Price = table.Column<decimal>(type: "numeric(12,2)", nullable: false),
                    Description = table.Column<string>(type: "text", nullable: true),
                    Color = table.Column<string>(type: "text", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    Status = table.Column<string>(type: "text", nullable: false),
                    ReservedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    ReservedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    OrderId = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventSeats", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventSeats_EventSeatBlocks_EventSeatBlockId",
                        column: x => x.EventSeatBlockId,
                        principalTable: "EventSeatBlocks",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EventStages",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    EventFloorId = table.Column<Guid>(type: "uuid", nullable: false),
                    CanvasX = table.Column<double>(type: "double precision", nullable: false),
                    CanvasY = table.Column<double>(type: "double precision", nullable: false),
                    Width = table.Column<double>(type: "double precision", nullable: false),
                    Height = table.Column<double>(type: "double precision", nullable: false),
                    Label = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EventStages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EventStages_EventFloors_EventFloorId",
                        column: x => x.EventFloorId,
                        principalTable: "EventFloors",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // ── Лог резерваций ─────────────────────────────────────────
            migrationBuilder.CreateTable(
                name: "SeatReservations",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SessionId = table.Column<string>(type: "text", nullable: false),
                    EventSeatId = table.Column<Guid>(type: "uuid", nullable: false),
                    ReservedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SeatReservations", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SeatReservations_EventSeats_EventSeatId",
                        column: x => x.EventSeatId,
                        principalTable: "EventSeats",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // ── Индексы ────────────────────────────────────────────────
            migrationBuilder.CreateIndex(
                name: "IX_VenueLayouts_Name",
                table: "VenueLayouts",
                column: "Name");

            migrationBuilder.CreateIndex(
                name: "IX_VenueLayouts_VenueId",
                table: "VenueLayouts",
                column: "VenueId");

            migrationBuilder.CreateIndex(
                name: "IX_VenueFloors_VenueLayoutId",
                table: "VenueFloors",
                column: "VenueLayoutId");

            migrationBuilder.CreateIndex(
                name: "IX_SeatBlocks_VenueFloorId",
                table: "SeatBlocks",
                column: "VenueFloorId");

            migrationBuilder.CreateIndex(
                name: "IX_Seats_SeatBlockId",
                table: "Seats",
                column: "SeatBlockId");

            migrationBuilder.CreateIndex(
                name: "IX_Stages_VenueFloorId",
                table: "Stages",
                column: "VenueFloorId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventLayouts_EventId",
                table: "EventLayouts",
                column: "EventId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_EventLayouts_VenueLayoutId",
                table: "EventLayouts",
                column: "VenueLayoutId");

            migrationBuilder.CreateIndex(
                name: "IX_EventFloors_EventLayoutId",
                table: "EventFloors",
                column: "EventLayoutId");

            migrationBuilder.CreateIndex(
                name: "IX_EventSeatBlocks_EventFloorId",
                table: "EventSeatBlocks",
                column: "EventFloorId");

            migrationBuilder.CreateIndex(
                name: "IX_EventSeats_EventSeatBlockId",
                table: "EventSeats",
                column: "EventSeatBlockId");

            migrationBuilder.CreateIndex(
                name: "IX_EventSeats_Status",
                table: "EventSeats",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_EventStages_EventFloorId",
                table: "EventStages",
                column: "EventFloorId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SeatReservations_EventSeatId",
                table: "SeatReservations",
                column: "EventSeatId");

            migrationBuilder.CreateIndex(
                name: "IX_SeatReservations_ExpiresAt",
                table: "SeatReservations",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_SeatReservations_SessionId",
                table: "SeatReservations",
                column: "SessionId");

            migrationBuilder.CreateIndex(
                name: "IX_SeatReservations_SessionId_EventSeatId",
                table: "SeatReservations",
                columns: new[] { "SessionId", "EventSeatId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "SeatReservations");
            migrationBuilder.DropTable(name: "Seats");
            migrationBuilder.DropTable(name: "Stages");
            migrationBuilder.DropTable(name: "EventStages");
            migrationBuilder.DropTable(name: "EventSeats");
            migrationBuilder.DropTable(name: "SeatBlocks");
            migrationBuilder.DropTable(name: "EventSeatBlocks");
            migrationBuilder.DropTable(name: "VenueFloors");
            migrationBuilder.DropTable(name: "EventFloors");
            migrationBuilder.DropTable(name: "EventLayouts");
            migrationBuilder.DropTable(name: "VenueLayouts");
        }
    }
}
