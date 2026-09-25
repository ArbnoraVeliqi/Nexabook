//using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using Microsoft.EntityFrameworkCore;using NexaBook.Api.Data;using NexaBook.Api.Models;
//namespace NexaBook.Api.Controllers;[ApiController,Route("api/finance"),Authorize(Roles="Owner,Manager,Staff")]public class FinanceController(AppDbContext db):ControllerBase{
// [HttpGet("payments")]public async Task<IActionResult>Payments()=>Ok(await db.Payments.Include(x=>x.Appointment).OrderByDescending(x=>x.PaidAt).ToListAsync());
// [HttpPost("payments")]public async Task<IActionResult>AddPayment(Payment p){db.Payments.Add(p);var a=await db.Appointments.FindAsync(p.AppointmentId);if(a is null)return BadRequest();var paid=await db.Payments.Where(x=>x.AppointmentId==p.AppointmentId).SumAsync(x=>(decimal?)x.Amount)??0;paid+=p.Amount;a.DepositAmount=await db.Payments.Where(x=>x.AppointmentId==p.AppointmentId&&x.IsDeposit).SumAsync(x=>(decimal?)x.Amount)??0;a.PaymentStatus=paid>=a.TotalAmount?PaymentStatus.Paid:PaymentStatus.PartiallyPaid;await db.SaveChangesAsync();return Ok(p);}
// [HttpGet("invoices")]public async Task<IActionResult>Invoices()=>Ok(await db.Invoices.Include(x=>x.Appointment).OrderByDescending(x=>x.IssuedAt).ToListAsync());
// [HttpPost("invoices/{appointmentId}")]public async Task<IActionResult>Invoice(int appointmentId){var a=await db.Appointments.FindAsync(appointmentId);if(a is null)return NotFound();var paid=await db.Payments.Where(x=>x.AppointmentId==appointmentId).SumAsync(x=>(decimal?)x.Amount)??0;var inv=new Invoice{Number=$"INV-{DateTime.Now:yyyy}-{DateTime.Now.Ticks%100000:00000}",AppointmentId=appointmentId,Subtotal=a.TotalAmount,Total=a.TotalAmount,PaidAmount=paid};db.Invoices.Add(inv);await db.SaveChangesAsync();return Ok(inv);}
// [HttpGet("expenses")]public async Task<IActionResult>Expenses()=>Ok(await db.Expenses.OrderByDescending(x=>x.ExpenseDate).ToListAsync());[HttpPost("expenses")]public async Task<IActionResult>AddExpense(Expense e){db.Expenses.Add(e);await db.SaveChangesAsync();return Ok(e);}}
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/finance")]
    [Authorize(Roles = "Owner,Manager,Staff")]
    public class FinanceController : ControllerBase
    {
        private readonly AppDbContext _db;

        public FinanceController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet("payments")]
        public async Task<IActionResult> Payments()
        {
            var payments = await _db.Payments
                .AsNoTracking()
                .Include(x => x.Appointment)
                    .ThenInclude(x => x.Customer)
                .Include(x => x.Appointment)
                    .ThenInclude(x => x.Service)
                .OrderByDescending(x => x.CreatedAt)
                .Select(x => new
                {
                    x.Id,
                    x.AppointmentId,
                    x.Amount,

                    method = x.Method.ToString(),

                    type = x.Type.ToString(),

                    x.Notes,
                    x.CreatedAt,

                    appointment = x.Appointment == null
                        ? null
                        : new
                        {
                            x.Appointment.Id,
                            x.Appointment.Reference,
                            x.Appointment.TotalAmount,

                            status =
                                x.Appointment.Status.ToString(),

                            client = x.Appointment.Customer == null
                                ? "Unknown client"
                                : (
                                    x.Appointment.Customer.FirstName +
                                    " " +
                                    x.Appointment.Customer.LastName
                                ).Trim(),

                            service = x.Appointment.Service == null
                                ? "Unknown service"
                                : x.Appointment.Service.Name
                        }
                })
                .ToListAsync();

            return Ok(payments);
        }

        [HttpPost("payments")]
        public async Task<IActionResult> AddPayment(
            Payment request)
        {
            if (request.Amount <= 0)
            {
                return BadRequest(new
                {
                    message =
                        "Payment amount must be greater than zero."
                });
            }

            var appointment = await _db.Appointments
                .Include(x => x.Payments)
                .FirstOrDefaultAsync(
                    x => x.Id == request.AppointmentId
                );

            if (appointment is null)
            {
                return BadRequest(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            var currentlyPaid =
                CalculatePaid(
                    appointment.Payments
                );

            var remaining = Math.Max(
                0,
                appointment.TotalAmount - currentlyPaid
            );

            if (request.Type != PaymentType.Refund)
            {
                if (remaining <= 0)
                {
                    return BadRequest(new
                    {
                        message =
                            "This appointment is already fully paid."
                    });
                }

                if (request.Amount > remaining)
                {
                    return BadRequest(new
                    {
                        message =
                            $"Only {remaining:0.00} remains to be paid."
                    });
                }
            }
            else
            {
                if (currentlyPaid <= 0)
                {
                    return BadRequest(new
                    {
                        message =
                            "There is no payment available to refund."
                    });
                }

                if (request.Amount > currentlyPaid)
                {
                    return BadRequest(new
                    {
                        message =
                            $"Only {currentlyPaid:0.00} can be refunded."
                    });
                }
            }

            var payment = new Payment
            {
                AppointmentId =
                    appointment.Id,

                Amount =
                    request.Amount,

                Method =
                    request.Method,

                Type =
                    request.Type,

                Notes =
                    request.Notes?.Trim(),

                CreatedAt =
                    DateTime.UtcNow
            };

            _db.Payments.Add(payment);

            await _db.SaveChangesAsync();

            var paidAfterPayment =
                request.Type == PaymentType.Refund
                    ? Math.Max(
                        0,
                        currentlyPaid - request.Amount
                    )
                    : currentlyPaid + request.Amount;

            var remainingAfterPayment =
                Math.Max(
                    0,
                    appointment.TotalAmount -
                    paidAfterPayment
                );

            var paymentStatus =
                GetPaymentStatus(
                    paidAfterPayment,
                    remainingAfterPayment
                );

            return Ok(new
            {
                payment = new
                {
                    payment.Id,
                    payment.AppointmentId,
                    payment.Amount,

                    method =
                        payment.Method.ToString(),

                    type =
                        payment.Type.ToString(),

                    payment.Notes,
                    payment.CreatedAt
                },

                summary = new
                {
                    totalAmount =
                        appointment.TotalAmount,

                    paidAmount =
                        paidAfterPayment,

                    remainingAmount =
                        remainingAfterPayment,

                    paymentStatus
                }
            });
        }

        [HttpGet("invoices")]
        public async Task<IActionResult> Invoices()
        {
            var invoices = await _db.Invoices
                .AsNoTracking()
                .Include(x => x.Appointment)
                    .ThenInclude(x => x.Customer)
                .Include(x => x.Appointment)
                    .ThenInclude(x => x.Service)
                .OrderByDescending(x => x.IssuedAt)
                .ToListAsync();

            return Ok(invoices);
        }

        [HttpPost("invoices/{appointmentId:int}")]
        public async Task<IActionResult> Invoice(
            int appointmentId)
        {
            var appointment = await _db.Appointments
                .Include(x => x.Payments)
                .FirstOrDefaultAsync(
                    x => x.Id == appointmentId
                );

            if (appointment is null)
            {
                return NotFound(new
                {
                    message =
                        "Appointment was not found."
                });
            }

            var existingInvoice =
                await _db.Invoices
                    .FirstOrDefaultAsync(
                        x =>
                            x.AppointmentId ==
                            appointmentId
                    );

            if (existingInvoice is not null)
            {
                return Ok(existingInvoice);
            }

            var paid =
                CalculatePaid(
                    appointment.Payments
                );

            var invoice = new Invoice
            {
                Number =
                    await GenerateInvoiceNumber(),

                AppointmentId =
                    appointment.Id,

                Subtotal =
                    appointment.TotalAmount,

                Total =
                    appointment.TotalAmount,

                PaidAmount =
                    paid
            };

            _db.Invoices.Add(invoice);

            await _db.SaveChangesAsync();

            return Ok(invoice);
        }

        [HttpGet("expenses")]
        public async Task<IActionResult> Expenses()
        {
            var expenses = await _db.Expenses
                .AsNoTracking()
                .OrderByDescending(
                    x => x.ExpenseDate
                )
                .ToListAsync();

            return Ok(expenses);
        }

        [HttpPost("expenses")]
        public async Task<IActionResult> AddExpense(
            Expense expense)
        {
            if (expense.Amount <= 0)
            {
                return BadRequest(new
                {
                    message =
                        "Expense amount must be greater than zero."
                });
            }

            if (string.IsNullOrWhiteSpace(
                    expense.Category))
            {
                return BadRequest(new
                {
                    message =
                        "Expense category is required."
                });
            }

            expense.Category =
                expense.Category.Trim();

            expense.Description =
                expense.Description?.Trim();

            expense.Vendor =
                expense.Vendor?.Trim();

            _db.Expenses.Add(expense);

            await _db.SaveChangesAsync();

            return Ok(expense);
        }

        private static decimal CalculatePaid(
            IEnumerable<Payment> payments)
        {
            var received = payments
                .Where(
                    x =>
                        x.Type !=
                        PaymentType.Refund
                )
                .Sum(x => x.Amount);

            var refunded = payments
                .Where(
                    x =>
                        x.Type ==
                        PaymentType.Refund
                )
                .Sum(x => x.Amount);

            return Math.Max(
                0,
                received - refunded
            );
        }

        private static string GetPaymentStatus(
            decimal paid,
            decimal remaining)
        {
            if (paid <= 0)
            {
                return "Unpaid";
            }

            if (remaining <= 0)
            {
                return "Paid";
            }

            return "PartiallyPaid";
        }

        private async Task<string>
            GenerateInvoiceNumber()
        {
            var year =
                DateTime.UtcNow.Year;

            var number =
                await _db.Invoices.CountAsync() + 1;

            while (true)
            {
                var invoiceNumber =
                    $"INV-{year}-{number:00000}";

                var exists =
                    await _db.Invoices.AnyAsync(
                        x =>
                            x.Number ==
                            invoiceNumber
                    );

                if (!exists)
                {
                    return invoiceNumber;
                }

                number++;
            }
        }
    }
}