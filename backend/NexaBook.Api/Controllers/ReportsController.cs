////using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using Microsoft.EntityFrameworkCore;using NexaBook.Api.Data;using NexaBook.Api.Models;
////namespace NexaBook.Api.Controllers;[ApiController,Route("api/reports"),Authorize(Roles="Owner,Manager")]public class ReportsController(AppDbContext db):ControllerBase{[HttpGet("summary")]public async Task<IActionResult>Summary(DateTime from,DateTime to){var a=await db.Appointments.Include(x=>x.Service).Include(x=>x.StaffProfile)!.ThenInclude(x=>x.User).Where(x=>x.StartAt>=from&&x.StartAt<=to).ToListAsync();var p=await db.Payments.Where(x=>x.PaidAt>=from&&x.PaidAt<=to).ToListAsync();return Ok(new{appointments=a.Count,revenue=p.Sum(x=>x.Amount),averageTicket=a.Count==0?0:a.Average(x=>x.TotalAmount),completed=a.Count(x=>x.Status==AppointmentStatus.Completed),cancelled=a.Count(x=>x.Status==AppointmentStatus.Cancelled),byStaff=a.GroupBy(x=>x.StaffProfile!.User!.FirstName+" "+x.StaffProfile.User.LastName).Select(g=>new{name=g.Key,appointments=g.Count(),revenue=g.Sum(x=>x.TotalAmount)}),byService=a.GroupBy(x=>x.Service!.Name).Select(g=>new{name=g.Key,count=g.Count(),revenue=g.Sum(x=>x.TotalAmount)})});}}
//using Microsoft.AspNetCore.Authorization;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using NexaBook.Api.Data;
//using NexaBook.Api.Models;

//namespace NexaBook.Api.Controllers
//{
//    [ApiController]
//    [Route("api/reports")]
//    [Authorize(Roles = "Owner,Manager")]
//    public class ReportsController : ControllerBase
//    {
//        private readonly AppDbContext _db;

//        public ReportsController(AppDbContext db)
//        {
//            _db = db;
//        }

//        [HttpGet("summary")]
//        public async Task<IActionResult> Summary(
//            DateTime from,
//            DateTime to)
//        {
//            if (to < from)
//            {
//                return BadRequest(new
//                {
//                    message = "The 'to' date must be after the 'from' date."
//                });
//            }

//            var appointments = await _db.Appointments
//                .AsNoTracking()
//                .Include(x => x.Service)
//                .Include(x => x.StaffProfile)
//                    .ThenInclude(x => x.User)
//                .Where(x =>
//                    x.StartTime >= from &&
//                    x.StartTime <= to)
//                .ToListAsync();

//            var payments = await _db.Payments
//                .AsNoTracking()
//                .Where(x =>
//                    x.CreatedAt >= from &&
//                    x.CreatedAt <= to)
//                .ToListAsync();

//            var receivedAmount = payments
//                .Where(x => x.Type != PaymentType.Refund)
//                .Sum(x => x.Amount);

//            var refundedAmount = payments
//                .Where(x => x.Type == PaymentType.Refund)
//                .Sum(x => x.Amount);

//            var revenue = Math.Max(
//                0,
//                receivedAmount - refundedAmount
//            );

//            var completed = appointments.Count(
//                x => x.Status == AppointmentStatus.Completed
//            );

//            var cancelled = appointments.Count(
//                x => x.Status == AppointmentStatus.Cancelled
//            );

//            var pending = appointments.Count(
//                x => x.Status == AppointmentStatus.Pending
//            );

//            var confirmed = appointments.Count(
//                x => x.Status == AppointmentStatus.Confirmed
//            );

//            var inProgress = appointments.Count(
//                x => x.Status == AppointmentStatus.InProgress
//            );

//            var noShow = appointments.Count(
//                x => x.Status == AppointmentStatus.NoShow
//            );

//            var expectedRevenue = appointments
//                .Where(x =>
//                    x.Status != AppointmentStatus.Cancelled &&
//                    x.Status != AppointmentStatus.NoShow)
//                .Sum(x => x.TotalAmount);

//            var averageTicket = appointments.Count == 0
//                ? 0
//                : appointments.Average(x => x.TotalAmount);

//            var byStaff = appointments
//                .GroupBy(x => GetStaffName(x.StaffProfile))
//                .Select(group => new
//                {
//                    name = group.Key,

//                    appointments = group.Count(),

//                    completed = group.Count(
//                        x => x.Status == AppointmentStatus.Completed
//                    ),

//                    revenue = group
//                        .Where(x =>
//                            x.Status == AppointmentStatus.Completed)
//                        .Sum(x => x.TotalAmount)
//                })
//                .OrderByDescending(x => x.revenue)
//                .ToList();

//            var byService = appointments
//                .GroupBy(x =>
//                    x.Service?.Name ?? "Unknown service")
//                .Select(group => new
//                {
//                    name = group.Key,

//                    count = group.Count(),

//                    completed = group.Count(
//                        x => x.Status == AppointmentStatus.Completed
//                    ),

//                    revenue = group
//                        .Where(x =>
//                            x.Status == AppointmentStatus.Completed)
//                        .Sum(x => x.TotalAmount)
//                })
//                .OrderByDescending(x => x.revenue)
//                .ToList();

//            var paymentMethods = payments
//                .Where(x => x.Type != PaymentType.Refund)
//                .GroupBy(x => x.Method)
//                .Select(group => new
//                {
//                    method = group.Key.ToString(),

//                    count = group.Count(),

//                    amount = group.Sum(x => x.Amount)
//                })
//                .OrderByDescending(x => x.amount)
//                .ToList();

//            var advances = payments
//                .Where(x => x.Type == PaymentType.Advance)
//                .Sum(x => x.Amount);

//            var refunds = payments
//                .Where(x => x.Type == PaymentType.Refund)
//                .Sum(x => x.Amount);

//            return Ok(new
//            {
//                from,
//                to,

//                appointments = appointments.Count,

//                statuses = new
//                {
//                    pending,
//                    confirmed,
//                    inProgress,
//                    completed,
//                    cancelled,
//                    noShow
//                },

//                financial = new
//                {
//                    revenue,
//                    expectedRevenue,
//                    advances,
//                    refunds,
//                    averageTicket
//                },

//                byStaff,

//                byService,

//                paymentMethods
//            });
//        }

//        private static string GetStaffName(
//            StaffProfile? staff)
//        {
//            if (staff?.User == null)
//            {
//                return "Unassigned";
//            }

//            var fullName =
//                $"{staff.User.FirstName} {staff.User.LastName}".Trim();

//            return string.IsNullOrWhiteSpace(fullName)
//                ? "Unknown team member"
//                : fullName;
//        }
//    }
//}
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/reports")]
    [Authorize(Roles = "Owner,Manager")]
    public class ReportsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public ReportsController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet("summary")]
        public async Task<IActionResult> Summary(
            DateTime from,
            DateTime to,
            int? staffId = null,
            int? serviceId = null,
            string? status = null,
            string groupBy = "daily")
        {
            if (to < from)
            {
                return BadRequest(new
                {
                    message = "The 'to' date must be after the 'from' date."
                });
            }

            if (to.TimeOfDay == TimeSpan.Zero)
            {
                to = to.Date.AddDays(1).AddTicks(-1);
            }

            var appointmentQuery = _db.Appointments
                .AsNoTracking()
                .Include(x => x.Service)
                .Include(x => x.StaffProfile)
                    .ThenInclude(x => x.User)
                .Where(x =>
                    x.StartTime >= from &&
                    x.StartTime <= to);

            if (staffId.HasValue)
            {
                appointmentQuery = appointmentQuery.Where(
                    x => x.StaffProfileId == staffId.Value
                );
            }

            if (serviceId.HasValue)
            {
                appointmentQuery = appointmentQuery.Where(
                    x => x.ServiceId == serviceId.Value
                );
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                if (!Enum.TryParse<AppointmentStatus>(
                        status,
                        true,
                        out var appointmentStatus))
                {
                    return BadRequest(new
                    {
                        message = "Invalid appointment status."
                    });
                }

                appointmentQuery = appointmentQuery.Where(
                    x => x.Status == appointmentStatus
                );
            }

            var appointments = await appointmentQuery.ToListAsync();

            var appointmentIds = appointments
                .Select(x => x.Id)
                .ToList();

            var payments = await _db.Payments
                .AsNoTracking()
                .Where(x =>
                    appointmentIds.Contains(x.AppointmentId) &&
                    x.CreatedAt >= from &&
                    x.CreatedAt <= to)
                .ToListAsync();

            var receivedAmount = payments
                .Where(x => x.Type != PaymentType.Refund)
                .Sum(x => x.Amount);

            var refundedAmount = payments
                .Where(x => x.Type == PaymentType.Refund)
                .Sum(x => x.Amount);

            var revenue = Math.Max(
                0,
                receivedAmount - refundedAmount
            );

            var expectedRevenue = appointments
                .Where(x =>
                    x.Status != AppointmentStatus.Cancelled &&
                    x.Status != AppointmentStatus.NoShow)
                .Sum(x => x.TotalAmount);

            var completed = appointments.Count(
                x => x.Status == AppointmentStatus.Completed
            );

            var cancelled = appointments.Count(
                x => x.Status == AppointmentStatus.Cancelled
            );

            var pending = appointments.Count(
                x => x.Status == AppointmentStatus.Pending
            );

            var confirmed = appointments.Count(
                x => x.Status == AppointmentStatus.Confirmed
            );

            var inProgress = appointments.Count(
                x => x.Status == AppointmentStatus.InProgress
            );

            var noShow = appointments.Count(
                x => x.Status == AppointmentStatus.NoShow
            );

            var averageTicket = appointments.Count == 0
                ? 0
                : appointments.Average(x => x.TotalAmount);

            var completionRate = appointments.Count == 0
                ? 0
                : Math.Round(
                    (decimal)completed / appointments.Count * 100,
                    1
                );

            var cancellationRate = appointments.Count == 0
                ? 0
                : Math.Round(
                    (decimal)cancelled / appointments.Count * 100,
                    1
                );

            var byStaff = appointments
                .GroupBy(x => new
                {
                    Id = x.StaffProfileId,
                    Name = GetStaffName(x.StaffProfile)
                })
                .Select(group => new
                {
                    id = group.Key.Id,
                    name = group.Key.Name,
                    appointments = group.Count(),

                    completed = group.Count(
                        x => x.Status == AppointmentStatus.Completed
                    ),

                    cancelled = group.Count(
                        x => x.Status == AppointmentStatus.Cancelled
                    ),

                    noShow = group.Count(
                        x => x.Status == AppointmentStatus.NoShow
                    ),

                    revenue = group
                        .Where(x =>
                            x.Status == AppointmentStatus.Completed)
                        .Sum(x => x.TotalAmount),

                    averageTicket = group.Any()
                        ? group.Average(x => x.TotalAmount)
                        : 0,

                    completionRate = group.Count() == 0
                        ? 0
                        : Math.Round(
                            (decimal)group.Count(
                                x => x.Status ==
                                     AppointmentStatus.Completed
                            ) / group.Count() * 100,
                            1
                        )
                })
                .OrderByDescending(x => x.revenue)
                .ToList();

            var byService = appointments
                .GroupBy(x => new
                {
                    Id = x.ServiceId,
                    Name = x.Service?.Name ?? "Unknown service"
                })
                .Select(group => new
                {
                    id = group.Key.Id,
                    name = group.Key.Name,
                    count = group.Count(),

                    completed = group.Count(
                        x => x.Status == AppointmentStatus.Completed
                    ),

                    cancelled = group.Count(
                        x => x.Status == AppointmentStatus.Cancelled
                    ),

                    revenue = group
                        .Where(x =>
                            x.Status == AppointmentStatus.Completed)
                        .Sum(x => x.TotalAmount),

                    averagePrice = group.Any()
                        ? group.Average(x => x.TotalAmount)
                        : 0
                })
                .OrderByDescending(x => x.revenue)
                .ToList();

            var paymentMethods = payments
                .Where(x => x.Type != PaymentType.Refund)
                .GroupBy(x => x.Method)
                .Select(group => new
                {
                    method = group.Key.ToString(),
                    count = group.Count(),
                    amount = group.Sum(x => x.Amount)
                })
                .OrderByDescending(x => x.amount)
                .ToList();

            var advances = payments
                .Where(x => x.Type == PaymentType.Advance)
                .Sum(x => x.Amount);

            var refunds = payments
                .Where(x => x.Type == PaymentType.Refund)
                .Sum(x => x.Amount);

            var timeline = BuildTimeline(
                appointments,
                payments,
                from,
                to,
                groupBy
            );

            var filters = await LoadFilters();

            return Ok(new
            {
                from,
                to,
                groupBy,

                appointments = appointments.Count,

                financial = new
                {
                    revenue,
                    expectedRevenue,
                    advances,
                    refunds,
                    averageTicket,
                    outstanding = Math.Max(
                        0,
                        expectedRevenue - revenue
                    )
                },

                statuses = new
                {
                    pending,
                    confirmed,
                    inProgress,
                    completed,
                    cancelled,
                    noShow
                },

                performance = new
                {
                    completionRate,
                    cancellationRate
                },

                byStaff,
                byService,
                paymentMethods,
                timeline,
                filters
            });
        }

        private object BuildTimeline(
            List<Appointment> appointments,
            List<Payment> payments,
            DateTime from,
            DateTime to,
            string groupBy)
        {
            groupBy = groupBy.Trim().ToLowerInvariant();

            if (groupBy == "monthly")
            {
                return BuildMonthlyTimeline(
                    appointments,
                    payments,
                    from,
                    to
                );
            }

            if (groupBy == "weekly")
            {
                return BuildWeeklyTimeline(
                    appointments,
                    payments,
                    from,
                    to
                );
            }

            return BuildDailyTimeline(
                appointments,
                payments,
                from,
                to
            );
        }

        private List<object> BuildDailyTimeline(
            List<Appointment> appointments,
            List<Payment> payments,
            DateTime from,
            DateTime to)
        {
            var result = new List<object>();

            var current = from.Date;
            var end = to.Date;

            while (current <= end)
            {
                var next = current.AddDays(1);

                var dayAppointments = appointments
                    .Where(x =>
                        x.StartTime >= current &&
                        x.StartTime < next)
                    .ToList();

                var dayPayments = payments
                    .Where(x =>
                        x.CreatedAt >= current &&
                        x.CreatedAt < next)
                    .ToList();

                result.Add(new
                {
                    key = current.ToString("yyyy-MM-dd"),
                    label = current.ToString("dd MMM"),

                    appointments = dayAppointments.Count,

                    completed = dayAppointments.Count(
                        x => x.Status ==
                             AppointmentStatus.Completed
                    ),

                    revenue = CalculateRevenue(
                        dayPayments
                    )
                });

                current = next;
            }

            return result;
        }

        private List<object> BuildWeeklyTimeline(
            List<Appointment> appointments,
            List<Payment> payments,
            DateTime from,
            DateTime to)
        {
            var result = new List<object>();

            var current = StartOfWeek(from.Date);

            while (current <= to.Date)
            {
                var weekEnd = current.AddDays(7);

                var effectiveFrom =
                    current < from ? from : current;

                var effectiveTo =
                    weekEnd > to ? to.AddTicks(1) : weekEnd;

                var weekAppointments = appointments
                    .Where(x =>
                        x.StartTime >= effectiveFrom &&
                        x.StartTime < effectiveTo)
                    .ToList();

                var weekPayments = payments
                    .Where(x =>
                        x.CreatedAt >= effectiveFrom &&
                        x.CreatedAt < effectiveTo)
                    .ToList();

                result.Add(new
                {
                    key = current.ToString("yyyy-MM-dd"),

                    label =
                        $"{current:dd MMM} - " +
                        $"{current.AddDays(6):dd MMM}",

                    appointments = weekAppointments.Count,

                    completed = weekAppointments.Count(
                        x => x.Status ==
                             AppointmentStatus.Completed
                    ),

                    revenue = CalculateRevenue(
                        weekPayments
                    )
                });

                current = weekEnd;
            }

            return result;
        }

        private List<object> BuildMonthlyTimeline(
            List<Appointment> appointments,
            List<Payment> payments,
            DateTime from,
            DateTime to)
        {
            var result = new List<object>();

            var current = new DateTime(
                from.Year,
                from.Month,
                1
            );

            while (current <= to)
            {
                var nextMonth = current.AddMonths(1);

                var effectiveFrom =
                    current < from ? from : current;

                var effectiveTo =
                    nextMonth > to ? to.AddTicks(1) : nextMonth;

                var monthAppointments = appointments
                    .Where(x =>
                        x.StartTime >= effectiveFrom &&
                        x.StartTime < effectiveTo)
                    .ToList();

                var monthPayments = payments
                    .Where(x =>
                        x.CreatedAt >= effectiveFrom &&
                        x.CreatedAt < effectiveTo)
                    .ToList();

                result.Add(new
                {
                    key = current.ToString("yyyy-MM"),
                    label = current.ToString("MMM yyyy"),

                    appointments = monthAppointments.Count,

                    completed = monthAppointments.Count(
                        x => x.Status ==
                             AppointmentStatus.Completed
                    ),

                    revenue = CalculateRevenue(
                        monthPayments
                    )
                });

                current = nextMonth;
            }

            return result;
        }

        private static decimal CalculateRevenue(
            IEnumerable<Payment> payments)
        {
            var received = payments
                .Where(x => x.Type != PaymentType.Refund)
                .Sum(x => x.Amount);

            var refunds = payments
                .Where(x => x.Type == PaymentType.Refund)
                .Sum(x => x.Amount);

            return Math.Max(
                0,
                received - refunds
            );
        }

        private async Task<object> LoadFilters()
        {
            var staff = await _db.StaffProfiles
                .AsNoTracking()
                .Include(x => x.User)
                .Where(x =>
                    x.AcceptsBookings &&
                    x.User != null)
                .OrderBy(x => x.User!.FirstName)
                .ThenBy(x => x.User!.LastName)
                .Select(x => new
                {
                    id = x.Id,

                    name =
                        ((x.User!.FirstName ?? "") +
                         " " +
                         (x.User.LastName ?? ""))
                        .Trim()
                })
                .ToListAsync();

            var services = await _db.Services
                .AsNoTracking()
                .Where(x => x.IsActive)
                .OrderBy(x => x.Name)
                .Select(x => new
                {
                    id = x.Id,
                    name = x.Name
                })
                .ToListAsync();

            return new
            {
                staff,
                services,

                statuses = Enum
                    .GetNames<AppointmentStatus>()
            };
        }

        private static DateTime StartOfWeek(
            DateTime date)
        {
            var difference =
                (7 +
                 (date.DayOfWeek - DayOfWeek.Monday)) %
                7;

            return date.AddDays(-difference).Date;
        }

        private static string GetStaffName(
            StaffProfile? staff)
        {
            if (staff?.User == null)
            {
                return "Unassigned";
            }

            var fullName =
                $"{staff.User.FirstName} " +
                $"{staff.User.LastName}";

            fullName = fullName.Trim();

            return string.IsNullOrWhiteSpace(fullName)
                ? "Unknown team member"
                : fullName;
        }
    }
}