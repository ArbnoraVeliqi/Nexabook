//using Microsoft.AspNetCore.Authorization;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using NexaBook.Api.Data;
//using NexaBook.Api.Models;
//namespace NexaBook.Api.Controllers; 
//[ApiController, Route("api/customers"),
//    Authorize(Roles = "Owner,Manager,Staff")]
//public class CustomersController(AppDbContext db) : ControllerBase 
//{
//    [HttpGet] 
//    public async Task<IActionResult> Get() => Ok(await db.Customers.OrderByDescending(x => x.CreatedAt).ToListAsync()); 
//    [HttpPost] public async Task<IActionResult> Add(Customer x) { db.Customers.Add(x); await db.SaveChangesAsync(); return Ok(x); }
//    [HttpPut("{id}")] public async Task<IActionResult> Update(int id, Customer x) { var e = await db.Customers.FindAsync(id); if (e is null) return NotFound(); e.FirstName = x.FirstName; e.LastName = x.LastName; e.Email = x.Email; e.Phone = x.Phone; e.Notes = x.Notes; await db.SaveChangesAsync(); return Ok(e); } }
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/customers")]
    [Authorize(Roles = "Owner,Manager,Staff")]
    public class CustomersController : ControllerBase
    {
        private readonly AppDbContext _db;

        public CustomersController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var customers = await _db.Customers
                .AsNoTracking()
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            return Ok(customers);
        }

        [HttpPost]
        public async Task<IActionResult> Add(
            [FromBody] CustomerRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FirstName))
            {
                return BadRequest("First name is required.");
            }

            var customer = new Customer
            {
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName?.Trim(),
                Email = request.Email?.Trim(),
                Phone = request.Phone?.Trim(),
                Notes = request.Notes?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _db.Customers.Add(customer);

            await _db.SaveChangesAsync();

            return Ok(customer);
        }

        [HttpPut("{id:int}")]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] CustomerRequest request)
        {
            var customer = await _db.Customers.FindAsync(id);

            if (customer == null)
            {
                return NotFound();
            }

            if (string.IsNullOrWhiteSpace(request.FirstName))
            {
                return BadRequest("First name is required.");
            }

            customer.FirstName = request.FirstName.Trim();
            customer.LastName = request.LastName?.Trim();
            customer.Email = request.Email?.Trim();
            customer.Phone = request.Phone?.Trim();
            customer.Notes = request.Notes?.Trim();

            await _db.SaveChangesAsync();

            return Ok(customer);
        }
    }

    public class CustomerRequest
    {
        public string FirstName { get; set; } = string.Empty;

        public string? LastName { get; set; }

        public string? Email { get; set; }

        public string? Phone { get; set; }

        public string? Notes { get; set; }
    }
}