using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/dashboard")]
    [Authorize(Roles = "Owner,Manager,Staff")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _db;

        public DashboardController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var today = DateTime.Today;

            var tomorrow = today.AddDays(1);

            var monthStart = new DateTime(
                today.Year,
                today.Month,
                1
            );

            var nextMonth = monthStart.AddMonths(1);

            var monthAppointments = await _db.Appointments
                .AsNoTracking()
                .Where(x =>
                    x.StartTime >= monthStart &&
                    x.StartTime < nextMonth)
                .ToListAsync();

            var todayAppointments = monthAppointments
                .Where(x =>
                    x.StartTime >= today &&
                    x.StartTime < tomorrow)
                .ToList();

            var monthPayments = await _db.Payments
                .AsNoTracking()
                .Where(x =>
                    x.CreatedAt >= monthStart &&
                    x.CreatedAt < nextMonth)
                .ToListAsync();

            var received = monthPayments
                .Where(x =>
                    x.Type != PaymentType.Refund)
                .Sum(x => x.Amount);

            var refunds = monthPayments
                .Where(x =>
                    x.Type == PaymentType.Refund)
                .Sum(x => x.Amount);

            var monthRevenue = Math.Max(
                0,
                received - refunds
            );

            var monthExpenses = await _db.Expenses
                .AsNoTracking()
                .Where(x =>
                    x.ExpenseDate >= monthStart &&
                    x.ExpenseDate < nextMonth)
                .SumAsync(x => (decimal?)x.Amount)
                ?? 0;

            var customerCount = await _db.Customers
                .AsNoTracking()
                .CountAsync();

            var pending = monthAppointments.Count(x =>
                x.Status == AppointmentStatus.Pending ||
                x.Status == AppointmentStatus.Confirmed
            );

            var completed = monthAppointments.Count(x =>
                x.Status == AppointmentStatus.Completed
            );

            var cancelled = monthAppointments.Count(x =>
                x.Status == AppointmentStatus.Cancelled
            );

            var noShow = monthAppointments.Count(x =>
                x.Status == AppointmentStatus.NoShow
            );

            var inProgress = monthAppointments.Count(x =>
                x.Status == AppointmentStatus.InProgress
            );

            var todayPending = todayAppointments.Count(x =>
                x.Status == AppointmentStatus.Pending
            );

            var todayConfirmed = todayAppointments.Count(x =>
                x.Status == AppointmentStatus.Confirmed
            );

            var todayCompleted = todayAppointments.Count(x =>
                x.Status == AppointmentStatus.Completed
            );

            var todayInProgress = todayAppointments.Count(x =>
                x.Status == AppointmentStatus.InProgress
            );

            var expectedMonthRevenue = monthAppointments
                .Where(x =>
                    x.Status != AppointmentStatus.Cancelled &&
                    x.Status != AppointmentStatus.NoShow)
                .Sum(x => x.TotalAmount);

            var outstandingAmount = Math.Max(
                0,
                expectedMonthRevenue - monthRevenue
            );

            return Ok(new
            {
                todayAppointments =
                    todayAppointments.Count,

                monthAppointments =
                    monthAppointments.Count,

                monthRevenue,

                expectedMonthRevenue,

                outstandingAmount,

                monthExpenses,

                net =
                    monthRevenue - monthExpenses,

                refunds,

                pending,

                inProgress,

                completed,

                cancelled,

                noShow,

                customers =
                    customerCount,

                today = new
                {
                    total =
                        todayAppointments.Count,

                    pending =
                        todayPending,

                    confirmed =
                        todayConfirmed,

                    inProgress =
                        todayInProgress,

                    completed =
                        todayCompleted
                }
            });
        }
    }
}