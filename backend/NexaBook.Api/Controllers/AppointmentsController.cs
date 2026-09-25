using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.DTOs;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/appointments")]
    [Authorize]
    public class AppointmentsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public AppointmentsController(
            AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get(
            DateTime? from = null,
            DateTime? to = null,
            int? staffId = null,
            int? serviceId = null,
            int? customerId = null,
            string? status = null,
            string? paymentStatus = null,
            string? search = null)
        {
            var query = _db.Appointments
                .AsNoTracking()
                .Include(x => x.Customer)
                .Include(x => x.Service)
                .Include(x => x.StaffProfile)
                    .ThenInclude(x => x.User)
                .Include(x => x.Payments)
                .AsQueryable();

            if (from.HasValue)
            {
                query = query.Where(
                    x => x.StartTime >= from.Value
                );
            }

            if (to.HasValue)
            {
                query = query.Where(
                    x => x.StartTime < to.Value
                );
            }

            if (staffId.HasValue)
            {
                query = query.Where(
                    x => x.StaffProfileId == staffId.Value
                );
            }

            if (serviceId.HasValue)
            {
                query = query.Where(
                    x => x.ServiceId == serviceId.Value
                );
            }

            if (customerId.HasValue)
            {
                query = query.Where(
                    x => x.CustomerId == customerId.Value
                );
            }

            if (!string.IsNullOrWhiteSpace(status) &&
                Enum.TryParse<AppointmentStatus>(
                    status,
                    true,
                    out var parsedStatus))
            {
                query = query.Where(
                    x => x.Status == parsedStatus
                );
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var term = search
                    .Trim()
                    .ToLower();

                query = query.Where(x =>
                    x.Reference.ToLower().Contains(term) ||
                    (
                        x.Customer != null &&
                        (
                            x.Customer.FirstName
                                .ToLower()
                                .Contains(term) ||

                            x.Customer.LastName
                                .ToLower()
                                .Contains(term) ||

                            x.Customer.Email
                                .ToLower()
                                .Contains(term)
                        )
                    ) ||
                    (
                        x.StaffProfile != null &&
                        x.StaffProfile.User != null &&
                        (
                            x.StaffProfile.User.FirstName
                                .ToLower()
                                .Contains(term) ||

                            x.StaffProfile.User.LastName
                                .ToLower()
                                .Contains(term)
                        )
                    )
                );
            }

            var appointments = await query
                .OrderBy(x => x.StartTime)
                .ToListAsync();

            var result = appointments
                .Select(MapAppointment)
                .ToList();

            if (!string.IsNullOrWhiteSpace(paymentStatus))
            {
                result = result
                    .Where(x =>
                        string.Equals(
                            x.PaymentStatus,
                            paymentStatus,
                            StringComparison.OrdinalIgnoreCase
                        ))
                    .ToList();
            }

            return Ok(result);
        }

        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetById(
            int id)
        {
            var appointment =
                await GetAppointmentQuery()
                    .AsNoTracking()
                    .FirstOrDefaultAsync(
                        x => x.Id == id
                    );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            return Ok(
                MapAppointment(appointment)
            );
        }

        [HttpPost]
        public async Task<IActionResult> Create(
            CreateAppointmentRequest request)
        {
            var customer = await _db.Customers
                .FindAsync(request.CustomerId);

            if (customer is null)
            {
                return BadRequest(new
                {
                    message =
                        "Customer was not found."
                });
            }

            var service = await _db.Services
                .FindAsync(request.ServiceId);

            if (service is null)
            {
                return BadRequest(new
                {
                    message =
                        "Service was not found."
                });
            }

            if (request.StaffProfileId.HasValue)
            {
                var staff = await _db.StaffProfiles
                    .Include(x => x.User)
                    .FirstOrDefaultAsync(
                        x =>
                            x.Id ==
                            request.StaffProfileId.Value
                    );

                if (staff is null)
                {
                    return BadRequest(new
                    {
                        message =
                            "Team member was not found."
                    });
                }

                if (!staff.AcceptsBookings)
                {
                    return BadRequest(new
                    {
                        message =
                            "This team member is not accepting bookings."
                    });
                }
            }

            var duration =
                GetServiceDuration(service);

            var total =
                request.TotalAmount ??
                GetServicePrice(service);

            if (total < 0)
            {
                return BadRequest(new
                {
                    message =
                        "Appointment total cannot be negative."
                });
            }

            if (request.AdvanceAmount.HasValue &&
                request.AdvanceAmount.Value < 0)
            {
                return BadRequest(new
                {
                    message =
                        "Advance amount cannot be negative."
                });
            }

            if (request.AdvanceAmount.HasValue &&
                request.AdvanceAmount.Value > total)
            {
                return BadRequest(new
                {
                    message =
                        "Advance cannot be greater than the appointment total."
                });
            }

            var endTime = request.StartTime
                .AddMinutes(duration);

            var conflict =
                await HasStaffConflict(
                    request.StaffProfileId,
                    request.StartTime,
                    endTime
                );

            if (conflict)
            {
                return Conflict(new
                {
                    message =
                        "The selected team member already has an appointment during this time."
                });
            }

            var appointment = new Appointment
            {
                Reference =
                    await GenerateReference(),

                CustomerId =
                    request.CustomerId,

                ServiceId =
                    request.ServiceId,

                StaffProfileId =
                    request.StaffProfileId,

                StartTime =
                    request.StartTime,

                EndTime =
                    endTime,

                TotalAmount =
                    total,

                Notes =
                    request.Notes?.Trim(),

                Status =
                    AppointmentStatus.Pending,

                Source =
                    "Business",

                CreatedAt =
                    DateTime.UtcNow
            };

            _db.Appointments.Add(
                appointment
            );

            await _db.SaveChangesAsync();

            if (request.AdvanceAmount.HasValue &&
                request.AdvanceAmount.Value > 0)
            {
                var payment = new Payment
                {
                    AppointmentId =
                        appointment.Id,

                    Amount =
                        request.AdvanceAmount.Value,

                    Method =
                        ParsePaymentMethod(
                            request.AdvancePaymentMethod
                        ),

                    Type =
                        PaymentType.Advance,

                    CreatedAt =
                        DateTime.UtcNow
                };

                _db.Payments.Add(payment);

                await _db.SaveChangesAsync();
            }

            return await GetById(
                appointment.Id
            );
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(
            int id,
            UpdateAppointmentRequest request)
        {
            var appointment =
                await _db.Appointments
                    .FirstOrDefaultAsync(
                        x => x.Id == id
                    );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            var customer =
                await _db.Customers.FindAsync(
                    request.CustomerId
                );

            if (customer is null)
            {
                return BadRequest(new
                {
                    message =
                        "Customer was not found."
                });
            }

            var service =
                await _db.Services.FindAsync(
                    request.ServiceId
                );

            if (service is null)
            {
                return BadRequest(new
                {
                    message =
                        "Service was not found."
                });
            }

            if (request.StaffProfileId.HasValue)
            {
                var staff =
                    await _db.StaffProfiles
                        .FirstOrDefaultAsync(
                            x =>
                                x.Id ==
                                request.StaffProfileId.Value
                        );

                if (staff is null)
                {
                    return BadRequest(new
                    {
                        message =
                            "Team member was not found."
                    });
                }

                if (!staff.AcceptsBookings)
                {
                    return BadRequest(new
                    {
                        message =
                            "This team member is not accepting bookings."
                    });
                }
            }

            var duration =
                GetServiceDuration(service);

            var endTime =
                request.StartTime
                    .AddMinutes(duration);

            var conflict =
                await HasStaffConflict(
                    request.StaffProfileId,
                    request.StartTime,
                    endTime,
                    appointment.Id
                );

            if (conflict)
            {
                return Conflict(new
                {
                    message =
                        "The selected team member already has an appointment during this time."
                });
            }

            appointment.CustomerId =
                request.CustomerId;

            appointment.ServiceId =
                request.ServiceId;

            appointment.StaffProfileId =
                request.StaffProfileId;

            appointment.StartTime =
                request.StartTime;

            appointment.EndTime =
                endTime;

            appointment.TotalAmount =
                request.TotalAmount ??
                GetServicePrice(service);

            appointment.Notes =
                request.Notes?.Trim();

            appointment.UpdatedAt =
                DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return await GetById(id);
        }

        [HttpPut("{id:int}/status")]
        public async Task<IActionResult> UpdateStatus(
            int id,
            UpdateAppointmentStatusRequest request)
        {
            var appointment =
                await _db.Appointments.FindAsync(id);

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            if (!Enum.TryParse<AppointmentStatus>(
                    request.Status,
                    true,
                    out var newStatus))
            {
                return BadRequest(new
                {
                    message =
                        "Invalid appointment status."
                });
            }

            if (!CanChangeStatus(
                    appointment.Status,
                    newStatus))
            {
                return BadRequest(new
                {
                    message =
                        $"Cannot change appointment from {appointment.Status} to {newStatus}."
                });
            }

            appointment.Status =
                newStatus;

            appointment.UpdatedAt =
                DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return await GetById(id);
        }

        [HttpPut("{id:int}/reschedule")]
        public async Task<IActionResult> Reschedule(
            int id,
            RescheduleAppointmentRequest request)
        {
            var appointment =
                await _db.Appointments
                    .Include(x => x.Service)
                    .FirstOrDefaultAsync(
                        x => x.Id == id
                    );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            if (appointment.Status is
                AppointmentStatus.Completed or
                AppointmentStatus.Cancelled or
                AppointmentStatus.NoShow)
            {
                return BadRequest(new
                {
                    message =
                        "This appointment cannot be rescheduled."
                });
            }

            var duration =
                appointment.Service != null
                    ? GetServiceDuration(
                        appointment.Service
                    )
                    : Math.Max(
                        1,
                        (int)(
                            appointment.EndTime -
                            appointment.StartTime
                        ).TotalMinutes
                    );

            var endTime =
                request.StartTime
                    .AddMinutes(duration);

            var conflict =
                await HasStaffConflict(
                    appointment.StaffProfileId,
                    request.StartTime,
                    endTime,
                    appointment.Id
                );

            if (conflict)
            {
                return Conflict(new
                {
                    message =
                        "The selected team member already has an appointment during this time."
                });
            }

            appointment.StartTime =
                request.StartTime;

            appointment.EndTime =
                endTime;

            appointment.UpdatedAt =
                DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return await GetById(id);
        }

        [HttpPut("{id:int}/assign")]
        public async Task<IActionResult> Assign(
            int id,
            ReassignAppointmentRequest request)
        {
            var appointment =
                await _db.Appointments
                    .FirstOrDefaultAsync(
                        x => x.Id == id
                    );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            if (appointment.Status is
                AppointmentStatus.Completed or
                AppointmentStatus.Cancelled or
                AppointmentStatus.NoShow)
            {
                return BadRequest(new
                {
                    message =
                        "The team member cannot be changed for this appointment."
                });
            }

            if (request.StaffProfileId.HasValue)
            {
                var staff =
                    await _db.StaffProfiles
                        .Include(x => x.User)
                        .FirstOrDefaultAsync(
                            x =>
                                x.Id ==
                                request.StaffProfileId.Value
                        );

                if (staff is null)
                {
                    return BadRequest(new
                    {
                        message =
                            "Team member was not found."
                    });
                }

                if (!staff.AcceptsBookings)
                {
                    return BadRequest(new
                    {
                        message =
                            "This team member is not accepting bookings."
                    });
                }

                var conflict =
                    await HasStaffConflict(
                        request.StaffProfileId,
                        appointment.StartTime,
                        appointment.EndTime,
                        appointment.Id
                    );

                if (conflict)
                {
                    return Conflict(new
                    {
                        message =
                            "The selected team member already has an appointment during this time."
                    });
                }
            }

            appointment.StaffProfileId =
                request.StaffProfileId;

            appointment.UpdatedAt =
                DateTime.UtcNow;

            await _db.SaveChangesAsync();

            return await GetById(id);
        }

        [HttpPost("{id:int}/payments")]
        public async Task<IActionResult> AddPayment(
            int id,
            RecordAppointmentPaymentRequest request)
        {
            if (request.Amount <= 0)
            {
                return BadRequest(new
                {
                    message =
                        "Payment amount must be greater than zero."
                });
            }

            var appointment =
                await _db.Appointments
                    .Include(x => x.Payments)
                    .FirstOrDefaultAsync(
                        x => x.Id == id
                    );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            var paymentType =
                ParsePaymentType(
                    request.Type
                );

            var paid =
                CalculatePaid(
                    appointment.Payments
                );

            var remaining =
                Math.Max(
                    0,
                    appointment.TotalAmount - paid
                );

            if (paymentType != PaymentType.Refund &&
                request.Amount > remaining)
            {
                return BadRequest(new
                {
                    message =
                        $"Only {remaining:0.00} remains to be paid."
                });
            }

            if (paymentType == PaymentType.Refund &&
                request.Amount > paid)
            {
                return BadRequest(new
                {
                    message =
                        $"Only {paid:0.00} can be refunded."
                });
            }

            var payment = new Payment
            {
                AppointmentId =
                    appointment.Id,

                Amount =
                    request.Amount,

                Method =
                    ParsePaymentMethod(
                        request.Method
                    ),

                Type =
                    paymentType,

                Notes =
                    request.Notes?.Trim(),

                CreatedAt =
                    DateTime.UtcNow
            };

            _db.Payments.Add(payment);

            await _db.SaveChangesAsync();

            return await GetById(id);
        }

        [HttpGet("{id:int}/payments")]
        public async Task<IActionResult> GetPayments(
            int id)
        {
            var exists =
                await _db.Appointments.AnyAsync(
                    x => x.Id == id
                );

            if (!exists)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            var payments =
                await _db.Payments
                    .AsNoTracking()
                    .Where(
                        x =>
                            x.AppointmentId == id
                    )
                    .OrderByDescending(
                        x => x.CreatedAt
                    )
                    .Select(x => new
                    {
                        x.Id,
                        x.Amount,

                        method =
                            x.Method.ToString(),

                        type =
                            x.Type.ToString(),

                        x.Notes,
                        x.CreatedAt
                    })
                    .ToListAsync();

            return Ok(payments);
        }

        [HttpGet("team")]
        public async Task<IActionResult> GetTeam()
        {
            var staff =
                await _db.StaffProfiles
                    .AsNoTracking()
                    .Include(x => x.User)
                    .OrderBy(x =>
                        x.User != null
                            ? x.User.FirstName
                            : string.Empty
                    )
                    .Select(x => new
                    {
                        x.Id,

                        FullName =
                            x.User == null
                                ? "Unknown team member"
                                : (
                                    x.User.FirstName +
                                    " " +
                                    x.User.LastName
                                ).Trim(),

                        x.JobTitle,

                        x.CommissionPercent,

                        x.AcceptsBookings
                    })
                    .ToListAsync();

            return Ok(staff);
        }

        private IQueryable<Appointment>
            GetAppointmentQuery()
        {
            return _db.Appointments
                .Include(x => x.Customer)
                .Include(x => x.Service)
                .Include(x => x.StaffProfile)
                    .ThenInclude(x => x.User)
                .Include(x => x.Payments);
        }

        private async Task<bool> HasStaffConflict(
            int? staffId,
            DateTime start,
            DateTime end,
            int? ignoreAppointmentId = null)
        {
            if (!staffId.HasValue)
            {
                return false;
            }

            var query =
                _db.Appointments
                    .Where(x =>
                        x.StaffProfileId ==
                            staffId.Value &&

                        x.Status !=
                            AppointmentStatus.Cancelled &&

                        x.Status !=
                            AppointmentStatus.NoShow &&

                        x.StartTime < end &&

                        x.EndTime > start
                    );

            if (ignoreAppointmentId.HasValue)
            {
                query = query.Where(
                    x =>
                        x.Id !=
                        ignoreAppointmentId.Value
                );
            }

            return await query.AnyAsync();
        }

        private static bool CanChangeStatus(
            AppointmentStatus current,
            AppointmentStatus next)
        {
            if (current == next)
            {
                return true;
            }

            return current switch
            {
                AppointmentStatus.Pending =>
                    next is
                        AppointmentStatus.Confirmed or
                        AppointmentStatus.Cancelled or
                        AppointmentStatus.NoShow,

                AppointmentStatus.Confirmed =>
                    next is
                        AppointmentStatus.InProgress or
                        AppointmentStatus.Cancelled or
                        AppointmentStatus.NoShow,

                AppointmentStatus.InProgress =>
                    next is
                        AppointmentStatus.Completed or
                        AppointmentStatus.Cancelled,

                AppointmentStatus.Completed =>
                    false,

                AppointmentStatus.Cancelled =>
                    false,

                AppointmentStatus.NoShow =>
                    false,

                _ =>
                    false
            };
        }

        private async Task<string>
            GenerateReference()
        {
            var year =
                DateTime.UtcNow.Year;

            var number =
                await _db.Appointments
                    .CountAsync() + 1;

            while (true)
            {
                var reference =
                    $"NB-{year}-{number:0000}";

                var exists =
                    await _db.Appointments
                        .AnyAsync(
                            x =>
                                x.Reference ==
                                reference
                        );

                if (!exists)
                {
                    return reference;
                }

                number++;
            }
        }

        private static PaymentMethod
            ParsePaymentMethod(
                string? value)
        {
            if (Enum.TryParse<PaymentMethod>(
                    value,
                    true,
                    out var method))
            {
                return method;
            }

            return PaymentMethod.Cash;
        }

        private static PaymentType
            ParsePaymentType(
                string? value)
        {
            if (Enum.TryParse<PaymentType>(
                    value,
                    true,
                    out var type))
            {
                return type;
            }

            return PaymentType.Payment;
        }

        private static decimal CalculatePaid(
            IEnumerable<Payment> payments)
        {
            var received =
                payments
                    .Where(
                        x =>
                            x.Type !=
                            PaymentType.Refund
                    )
                    .Sum(
                        x => x.Amount
                    );

            var refunded =
                payments
                    .Where(
                        x =>
                            x.Type ==
                            PaymentType.Refund
                    )
                    .Sum(
                        x => x.Amount
                    );

            return Math.Max(
                0,
                received - refunded
            );
        }

        private static decimal CalculateAdvance(
            IEnumerable<Payment> payments)
        {
            var advance =
                payments
                    .Where(
                        x =>
                            x.Type ==
                            PaymentType.Advance
                    )
                    .Sum(
                        x => x.Amount
                    );

            return Math.Max(
                0,
                advance
            );
        }

        private static AppointmentResponse
            MapAppointment(
                Appointment appointment)
        {
            var paid =
                CalculatePaid(
                    appointment.Payments
                );

            var advance =
                CalculateAdvance(
                    appointment.Payments
                );

            var remaining =
                Math.Max(
                    0,
                    appointment.TotalAmount -
                    paid
                );

            string paymentStatus;

            if (paid <= 0)
            {
                paymentStatus = "Unpaid";
            }
            else if (remaining <= 0)
            {
                paymentStatus = "Paid";
            }
            else
            {
                paymentStatus =
                    "PartiallyPaid";
            }

            return new AppointmentResponse
            {
                Id =
                    appointment.Id,

                Reference =
                    appointment.Reference,

                Client =
                    new AppointmentClientResponse
                    {
                        Id =
                            appointment.CustomerId,

                        FullName =
                            appointment.Customer == null
                                ? "Unknown client"
                                : (
                                    appointment.Customer.FirstName +
                                    " " +
                                    appointment.Customer.LastName
                                ).Trim(),

                        Email =
                            appointment.Customer?.Email,

                        Phone =
                            appointment.Customer?.Phone
                    },

                Service =
                    new AppointmentServiceResponse
                    {
                        Id =
                            appointment.ServiceId,

                        Name =
                            GetServiceName(
                                appointment.Service
                            )
                    },

                Staff =
                    appointment.StaffProfile == null
                        ? null
                        : new AppointmentStaffResponse
                        {
                            Id =
                                appointment.StaffProfileId,

                            FullName =
                                GetStaffName(
                                    appointment.StaffProfile
                                ),

                            JobTitle =
                                appointment
                                    .StaffProfile
                                    .JobTitle
                        },

                StartTime =
                    appointment.StartTime,

                EndTime =
                    appointment.EndTime,

                DurationMinutes =
                    Math.Max(
                        0,
                        (int)(
                            appointment.EndTime -
                            appointment.StartTime
                        ).TotalMinutes
                    ),

                Status =
                    appointment.Status
                        .ToString(),

                TotalAmount =
                    appointment.TotalAmount,

                PaidAmount =
                    paid,

                AdvanceAmount =
                    advance,

                RemainingAmount =
                    remaining,

                PaymentStatus =
                    paymentStatus,

                Notes =
                    appointment.Notes,

                Source =
                    appointment.Source,

                CreatedAt =
                    appointment.CreatedAt
            };
        }

        private static string GetStaffName(
            StaffProfile staff)
        {
            if (staff.User is null)
            {
                return "Unknown team member";
            }

            var fullName =
                $"{staff.User.FirstName} {staff.User.LastName}"
                    .Trim();

            return string.IsNullOrWhiteSpace(
                fullName
            )
                ? "Unknown team member"
                : fullName;
        }

        private static string GetServiceName(
            Service? service)
        {
            if (service is null)
            {
                return "Unknown service";
            }

            return service.Name;
        }

        private static decimal GetServicePrice(
            Service service)
        {
            return service.Price;
        }

        private static int GetServiceDuration(
            Service service)
        {
            return service.DurationMinutes;
        }
    }
}