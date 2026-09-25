namespace NexaBook.Api.DTOs
{
    //public class CreateAppointmentRequest
    //{
    //    public int CustomerId { get; set; }

    //    public int ServiceId { get; set; }

    //    public int? StaffProfileId { get; set; }

    //    public DateTime StartTime { get; set; }

    //    public string? Notes { get; set; }

    //    public decimal? TotalAmount { get; set; }

    //    public decimal? AdvanceAmount { get; set; }

    //    public string? AdvancePaymentMethod { get; set; }
    //}

    //public class UpdateAppointmentRequest
    //{
    //    public int CustomerId { get; set; }

    //    public int ServiceId { get; set; }

    //    public int? StaffProfileId { get; set; }

    //    public DateTime StartTime { get; set; }

    //    public string? Notes { get; set; }

    //    public decimal? TotalAmount { get; set; }
    //}

    //public class UpdateAppointmentStatusRequest
    //{
    //    public string Status { get; set; } = string.Empty;
    //}

    //public class ReassignAppointmentRequest
    //{
    //    public int? StaffProfileId { get; set; }
    //}

    //public class RescheduleAppointmentRequest
    //{
    //    public DateTime StartTime { get; set; }
    //}

    //public class RecordAppointmentPaymentRequest
    //{
    //    public decimal Amount { get; set; }

    //    public string Method { get; set; } = "Cash";

    //    public string Type { get; set; } = "Payment";

    //    public string? Notes { get; set; }
    //}

    public class CreateAppointmentRequest
    {
        public int CustomerId { get; set; }

        public int ServiceId { get; set; }

        public int? StaffProfileId { get; set; }

        public DateTime StartTime { get; set; }

        public string? Notes { get; set; }

        public decimal? TotalAmount { get; set; }

        public decimal? AdvanceAmount { get; set; }

        public string? AdvancePaymentMethod { get; set; }
    }

    public class UpdateAppointmentRequest
    {
        public int CustomerId { get; set; }

        public int ServiceId { get; set; }

        public int? StaffProfileId { get; set; }

        public DateTime StartTime { get; set; }

        public string? Notes { get; set; }

        public decimal? TotalAmount { get; set; }
    }

    public class UpdateAppointmentStatusRequest
    {
        public string Status { get; set; } = string.Empty;
    }

    public class ReassignAppointmentRequest
    {
        public int? StaffProfileId { get; set; }
    }

    public class RescheduleAppointmentRequest
    {
        public DateTime StartTime { get; set; }
    }

    public class RecordAppointmentPaymentRequest
    {
        public decimal Amount { get; set; }

        public string Method { get; set; } = "Cash";

        public string Type { get; set; } = "Payment";

        public string? Notes { get; set; }
    }
}