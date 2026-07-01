using Microsoft.EntityFrameworkCore;
using TelcellTickets.Api.Models;

namespace TelcellTickets.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Venue> Venues => Set<Venue>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<TicketType> TicketTypes => Set<TicketType>();
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<Ticket> Tickets => Set<Ticket>();

    // ── Схемы залов: шаблоны ──────────────────────────────────────────
    public DbSet<VenueLayout> VenueLayouts => Set<VenueLayout>();
    public DbSet<VenueFloor> VenueFloors => Set<VenueFloor>();
    public DbSet<SeatBlock> SeatBlocks => Set<SeatBlock>();
    public DbSet<Seat> Seats => Set<Seat>();
    public DbSet<Stage> Stages => Set<Stage>();

    // ── Схемы залов: копия под конкретное событие + реалтайм ──────────
    public DbSet<EventLayout> EventLayouts => Set<EventLayout>();
    public DbSet<EventFloor> EventFloors => Set<EventFloor>();
    public DbSet<EventSeatBlock> EventSeatBlocks => Set<EventSeatBlock>();
    public DbSet<EventSeat> EventSeats => Set<EventSeat>();
    public DbSet<EventStage> EventStages => Set<EventStage>();
    public DbSet<SeatReservation> SeatReservations => Set<SeatReservation>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.Entity<Event>()
            .HasOne(e => e.Venue)
            .WithMany(v => v.Events)
            .HasForeignKey(e => e.VenueId)
            .OnDelete(DeleteBehavior.Restrict);

        b.Entity<TicketType>()
            .HasOne(t => t.Event)
            .WithMany(e => e.TicketTypes)
            .HasForeignKey(t => t.EventId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<TicketType>().Ignore(t => t.Available);
        b.Entity<TicketType>().Property(t => t.Price).HasColumnType("numeric(12,2)");
        b.Entity<Order>().Property(o => o.Total).HasColumnType("numeric(12,2)");

        b.Entity<Order>()
            .HasOne(o => o.User)
            .WithMany()
            .HasForeignKey(o => o.UserId);

        b.Entity<Ticket>()
            .HasOne(t => t.Order)
            .WithMany(o => o.Tickets)
            .HasForeignKey(t => t.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<Ticket>()
            .HasIndex(t => t.QrToken)
            .IsUnique();

        // enum -> string в БД (читаемо для дебага)
        b.Entity<Event>().Property(e => e.Category).HasConversion<string>();
        b.Entity<Ticket>().Property(t => t.Status).HasConversion<string>();
        b.Entity<Order>().Property(o => o.Status).HasConversion<string>();

        ConfigureSeatingPlan(b);
    }

    // ═══════════════════════════════════════════════════════════════════
    //  СХЕМЫ ЗАЛОВ (Часть 1)
    // ═══════════════════════════════════════════════════════════════════
    private static void ConfigureSeatingPlan(ModelBuilder b)
    {
        // ── Шаблоны залов ──────────────────────────────────────────────
        b.Entity<VenueLayout>(e =>
        {
            e.HasOne(x => x.Venue)
                .WithMany()
                .HasForeignKey(x => x.VenueId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => x.Name);
        });

        b.Entity<VenueFloor>()
            .HasOne(x => x.VenueLayout)
            .WithMany(l => l.Floors)
            .HasForeignKey(x => x.VenueLayoutId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<SeatBlock>(e =>
        {
            e.HasOne(x => x.VenueFloor)
                .WithMany(f => f.SeatBlocks)
                .HasForeignKey(x => x.VenueFloorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.SeatType).HasConversion<string>();
            e.Property(x => x.DefaultPrice).HasColumnType("numeric(12,2)");
        });

        b.Entity<Seat>(e =>
        {
            e.HasOne(x => x.SeatBlock)
                .WithMany(sb => sb.Seats)
                .HasForeignKey(x => x.SeatBlockId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.SeatType).HasConversion<string>();
            e.Property(x => x.Price).HasColumnType("numeric(12,2)");
        });

        // Один Stage на этаж — уникальный FK.
        b.Entity<Stage>(e =>
        {
            e.HasOne(x => x.VenueFloor)
                .WithOne(f => f.Stage!)
                .HasForeignKey<Stage>(x => x.VenueFloorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.VenueFloorId).IsUnique();
        });

        // ── Схема события (копия) ──────────────────────────────────────
        b.Entity<EventLayout>(e =>
        {
            e.HasOne(x => x.Event)
                .WithMany()
                .HasForeignKey(x => x.EventId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.EventId).IsUnique();

            // Ссылка на шаблон-источник не каскадит: удаление шаблона
            // не должно трогать уже снятые копии событий.
            e.HasOne(x => x.VenueLayout)
                .WithMany()
                .HasForeignKey(x => x.VenueLayoutId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        b.Entity<EventFloor>()
            .HasOne(x => x.EventLayout)
            .WithMany(l => l.Floors)
            .HasForeignKey(x => x.EventLayoutId)
            .OnDelete(DeleteBehavior.Cascade);

        b.Entity<EventSeatBlock>(e =>
        {
            e.HasOne(x => x.EventFloor)
                .WithMany(f => f.SeatBlocks)
                .HasForeignKey(x => x.EventFloorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.SeatType).HasConversion<string>();
            e.Property(x => x.DefaultPrice).HasColumnType("numeric(12,2)");
        });

        b.Entity<EventSeat>(e =>
        {
            e.HasOne(x => x.EventSeatBlock)
                .WithMany(sb => sb.Seats)
                .HasForeignKey(x => x.EventSeatBlockId)
                .OnDelete(DeleteBehavior.Cascade);
            e.Property(x => x.SeatType).HasConversion<string>();
            e.Property(x => x.Status).HasConversion<string>();
            e.Property(x => x.Price).HasColumnType("numeric(12,2)");
            e.HasIndex(x => x.Status);
        });

        b.Entity<EventStage>(e =>
        {
            e.HasOne(x => x.EventFloor)
                .WithOne(f => f.Stage!)
                .HasForeignKey<EventStage>(x => x.EventFloorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.EventFloorId).IsUnique();
        });

        // ── Лог резерваций ─────────────────────────────────────────────
        b.Entity<SeatReservation>(e =>
        {
            e.HasOne(x => x.EventSeat)
                .WithMany()
                .HasForeignKey(x => x.EventSeatId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.SessionId);
            e.HasIndex(x => x.ExpiresAt);
            e.HasIndex(x => new { x.SessionId, x.EventSeatId }).IsUnique();
        });
    }
}
