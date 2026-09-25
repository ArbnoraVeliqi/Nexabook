using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/client/invoices")]
    [Authorize(Roles = "Client")]
    public class ClientInvoicesController : ControllerBase
    {
        private readonly AppDbContext _db;

        public ClientInvoicesController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var userIdText = User.FindFirstValue(
                ClaimTypes.NameIdentifier
            );

            if (!int.TryParse(userIdText, out var userId))
            {
                return Unauthorized();
            }

            var customer = await _db.Customers
                .FirstOrDefaultAsync(x => x.UserId == userId);

            if (customer == null)
            {
                return Ok(Array.Empty<object>());
            }

            var invoices = await _db.Invoices
                .AsNoTracking()
                .Where(x =>
                    x.Appointment != null &&
                    x.Appointment.CustomerId == customer.Id)
                .OrderByDescending(x => x.IssuedAt)
                .Select(x => new
                {
                    x.Id,
                    x.Number,
                    x.AppointmentId,
                    x.Subtotal,
                    x.TaxAmount,
                    x.Total,
                    x.PaidAmount,
                    x.IssuedAt
                })
                .ToListAsync();

            return Ok(invoices);
        }
    }
}