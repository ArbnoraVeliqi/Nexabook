namespace NexaBook.Api.DTOs
{
    public class AppointmentResponse
    {
        public int Id { get; set; }

        public string Reference { get; set; } =
            string.Empty;

        public AppointmentClientResponse Client { get; set; } =
            new();

        public AppointmentServiceResponse Service { get; set; } =
            new();

        public AppointmentStaffResponse? Staff { get; set; }

        public DateTime StartTime { get; set; }

        public DateTime EndTime { get; set; }

        public int DurationMinutes { get; set; }

        public string Status { get; set; } =
            string.Empty;

        public decimal TotalAmount { get; set; }

        public decimal PaidAmount { get; set; }

        public decimal AdvanceAmount { get; set; }

        public decimal RemainingAmount { get; set; }

        public string PaymentStatus { get; set; } =
            string.Empty;

        public string? Notes { get; set; }

        public string? Source { get; set; }

        public DateTime CreatedAt { get; set; }
    }

    public class AppointmentClientResponse
    {
        public int Id { get; set; }

        public string FullName { get; set; } =
            string.Empty;

        public string? Email { get; set; }

        public string? Phone { get; set; }
    }

    public class AppointmentServiceResponse
    {
        public int Id { get; set; }

        public string Name { get; set; } =
            string.Empty;
    }

    public class AppointmentStaffResponse
    {
        public int? Id { get; set; }

        public string FullName { get; set; } =
            string.Empty;

        public string? JobTitle { get; set; }
    }
}