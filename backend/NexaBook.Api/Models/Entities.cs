using System.ComponentModel.DataAnnotations;

namespace NexaBook.Api.Models;

public enum UserRole { Owner, Manager, Staff, Client }
public enum AppointmentStatus { Pending, Confirmed, InProgress, Completed, Cancelled, NoShow }
public enum PaymentStatus { Pending, PartiallyPaid, Paid, Refunded }
public enum PaymentMethod { Cash, Card, BankTransfer, Online }
public class User { public int Id { get; set; } public string FirstName { get; set; } = ""; public string LastName { get; set; } = ""; public string Email { get; set; } = ""; public string PasswordHash { get; set; } = ""; public string? Phone { get; set; } public UserRole Role { get; set; } public bool IsActive { get; set; } = true; public DateTime CreatedAt { get; set; } = DateTime.UtcNow; }
public class Customer { public int Id { get; set; } public int? UserId { get; set; } public User? User { get; set; } public string FirstName { get; set; } = ""; public string LastName { get; set; } = ""; public string Email { get; set; } = ""; public string? Phone { get; set; } public string? Notes { get; set; } public DateTime CreatedAt { get; set; } = DateTime.UtcNow; }
public class ServiceCategory { public int Id { get; set; } public string Name { get; set; } = ""; public string? Description { get; set; } public bool IsActive { get; set; } = true; }
public class Service { public int Id { get; set; } public string Name { get; set; } = ""; public string? Description { get; set; } public decimal Price { get; set; } public int DurationMinutes { get; set; } public int CategoryId { get; set; } public ServiceCategory? Category { get; set; } public bool RequiresDeposit { get; set; } public decimal DepositAmount { get; set; } public bool IsActive { get; set; } = true; }
public class StaffProfile
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public User? User { get; set; }

    public string? JobTitle { get; set; }

    public decimal CommissionPercent { get; set; }

    public bool AcceptsBookings { get; set; } = true;
}
public class StaffService { public int StaffProfileId { get; set; } public StaffProfile? StaffProfile { get; set; } public int ServiceId { get; set; } public Service? Service { get; set; } }
public class WorkSchedule { public int Id { get; set; } public int StaffProfileId { get; set; } public DayOfWeek DayOfWeek { get; set; } public TimeSpan StartTime { get; set; } public TimeSpan EndTime { get; set; } public bool IsWorking { get; set; } = true; }
//public class Appointment { public int Id { get; set; } public string Reference { get; set; } = ""; public int CustomerId { get; set; } public Customer? Customer { get; set; } public int ServiceId { get; set; } public Service? Service { get; set; } public int StaffProfileId { get; set; } public StaffProfile? StaffProfile { get; set; } public DateTime StartAt { get; set; } public DateTime EndAt { get; set; } public AppointmentStatus Status { get; set; } public PaymentStatus PaymentStatus { get; set; } public decimal TotalAmount { get; set; } public decimal DepositAmount { get; set; } public string? Notes { get; set; } public DateTime CreatedAt { get; set; } = DateTime.UtcNow; }
public class Appointment
{
    public int Id { get; set; }

    [MaxLength(30)]
    public string Reference { get; set; } = string.Empty;

    public int CustomerId { get; set; }

    public Customer? Customer { get; set; }

    public int ServiceId { get; set; }

    public Service? Service { get; set; }

    public int? StaffProfileId { get; set; }

    public StaffProfile? StaffProfile { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public AppointmentStatus Status { get; set; } =
        AppointmentStatus.Pending;

    public decimal TotalAmount { get; set; }

    [MaxLength(1000)]
    public string? Notes { get; set; }

    [MaxLength(50)]
    public string? Source { get; set; }

    public DateTime CreatedAt { get; set; } =
        DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }

    public ICollection<Payment> Payments { get; set; } =
        new List<Payment>();
}

public enum PaymentType
{
    Advance,
    Payment,
    Refund
}

public class Payment
{
    public int Id { get; set; }

    public int AppointmentId { get; set; }

    public Appointment? Appointment { get; set; }

    public decimal Amount { get; set; }

    public PaymentMethod Method { get; set; }

    public PaymentType Type { get; set; }

    [MaxLength(500)]
    public string? Notes { get; set; }

    public DateTime CreatedAt { get; set; } =
        DateTime.UtcNow;
}
public class Invoice { public int Id { get; set; } public string Number { get; set; } = ""; public int AppointmentId { get; set; } public Appointment? Appointment { get; set; } public decimal Subtotal { get; set; } public decimal TaxAmount { get; set; } public decimal Total { get; set; } public decimal PaidAmount { get; set; } public DateTime IssuedAt { get; set; } = DateTime.UtcNow; }
public class Expense { public int Id { get; set; } public string Category { get; set; } = ""; public string Description { get; set; } = ""; public decimal Amount { get; set; } public DateTime ExpenseDate { get; set; } public string? Vendor { get; set; } }
public class Notification { public int Id { get; set; } public int UserId { get; set; } public string Title { get; set; } = ""; public string Message { get; set; } = ""; public bool IsRead { get; set; } public DateTime CreatedAt { get; set; } = DateTime.UtcNow; }
public class BusinessSetting { public int Id { get; set; } public string BusinessName { get; set; } = "Nexa Studio"; public string? Phone { get; set; } public string? Email { get; set; } public string Currency { get; set; } = "EUR"; public decimal TaxRate { get; set; } = 0; public int CancellationHours { get; set; } = 24; }

public class PasswordResetCode
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string CodeHash { get; set; } = string.Empty;

    public DateTime ExpiresAt { get; set; }

    public bool IsUsed { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}