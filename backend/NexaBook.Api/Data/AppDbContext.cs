using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Models;

namespace NexaBook.Api.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(
            DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        public DbSet<User> Users => Set<User>();

        public DbSet<Customer> Customers => Set<Customer>();

        public DbSet<ServiceCategory> ServiceCategories =>
            Set<ServiceCategory>();

        public DbSet<Service> Services => Set<Service>();

        public DbSet<StaffProfile> StaffProfiles =>
            Set<StaffProfile>();

        public DbSet<StaffService> StaffServices =>
            Set<StaffService>();

        public DbSet<WorkSchedule> WorkSchedules =>
            Set<WorkSchedule>();

        public DbSet<Appointment> Appointments =>
            Set<Appointment>();

        public DbSet<Payment> Payments =>
            Set<Payment>();

        public DbSet<Invoice> Invoices =>
            Set<Invoice>();

        public DbSet<Expense> Expenses =>
            Set<Expense>();

        public DbSet<Notification> Notifications =>
            Set<Notification>();

        public DbSet<BusinessSetting> BusinessSettings =>
            Set<BusinessSetting>();

        public DbSet<PasswordResetCode> PasswordResetCodes =>
            Set<PasswordResetCode>();

        protected override void OnModelCreating(
            ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>()
                .HasIndex(x => x.Email)
                .IsUnique();

            modelBuilder.Entity<Appointment>()
       .HasMany(x => x.Payments)
       .WithOne(x => x.Appointment)
       .HasForeignKey(x => x.AppointmentId)
       .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Appointment>()
                .HasOne(x => x.Customer)
                .WithMany()
                .HasForeignKey(x => x.CustomerId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(x => x.Service)
                .WithMany()
                .HasForeignKey(x => x.ServiceId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Appointment>()
                .HasOne(x => x.StaffProfile)
                .WithMany()
                .HasForeignKey(x => x.StaffProfileId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<Invoice>()
                .HasIndex(x => x.Number)
                .IsUnique();

            modelBuilder.Entity<StaffService>()
                .HasKey(x => new
                {
                    x.StaffProfileId,
                    x.ServiceId
                });

            modelBuilder.Entity<PasswordResetCode>()
                .HasOne(x => x.User)
                .WithMany()
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<PasswordResetCode>()
                .HasIndex(x => x.UserId);

            foreach (var entity in modelBuilder.Model.GetEntityTypes())
            {
                foreach (var property in entity.GetProperties()
                             .Where(x => x.ClrType == typeof(decimal)))
                {
                    property.SetColumnType("decimal(18,2)");
                }
            }
        }
    }
}