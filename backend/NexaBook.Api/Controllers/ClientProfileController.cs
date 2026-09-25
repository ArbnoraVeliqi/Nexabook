using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/client/profile")]
    [Authorize(Roles = "Client")]
    public class ClientProfileController : ControllerBase
    {
        private readonly AppDbContext _db;

        public ClientProfileController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var userId = GetUserId();

            if (userId == null)
            {
                return Unauthorized();
            }

            var user = await _db.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == userId.Value);

            if (user == null)
            {
                return NotFound();
            }

            return Ok(new
            {
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email,
                user.Phone
            });
        }

        [HttpPut]
        public async Task<IActionResult> Update(
            [FromBody] UpdateClientProfileRequest request)
        {
            var userId = GetUserId();

            if (userId == null)
            {
                return Unauthorized();
            }

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Id == userId.Value);

            if (user == null)
            {
                return NotFound();
            }

            if (string.IsNullOrWhiteSpace(request.FirstName))
            {
                return BadRequest(new
                {
                    message = "First name is required."
                });
            }

            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new
                {
                    message = "Email is required."
                });
            }

            var email = request.Email.Trim();

            var emailExists = await _db.Users.AnyAsync(
                x => x.Id != user.Id &&
                     x.Email.ToLower() == email.ToLower()
            );

            if (emailExists)
            {
                return BadRequest(new
                {
                    message = "Email is already in use."
                });
            }

            user.FirstName = request.FirstName.Trim();
            user.LastName = request.LastName?.Trim() ?? "";
            user.Email = email;
            user.Phone = request.Phone?.Trim();

            var customer = await _db.Customers
                .FirstOrDefaultAsync(x => x.UserId == user.Id);

            if (customer != null)
            {
                customer.FirstName = user.FirstName;
                customer.LastName = user.LastName;
                customer.Email = user.Email;
                customer.Phone = user.Phone;
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                user.Id,
                user.FirstName,
                user.LastName,
                user.Email,
                user.Phone
            });
        }

        [HttpPut("password")]
        public async Task<IActionResult> ChangePassword(
            [FromBody] ChangeClientPasswordRequest request)
        {
            var userId = GetUserId();

            if (userId == null)
            {
                return Unauthorized();
            }

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Id == userId.Value);

            if (user == null)
            {
                return NotFound();
            }

            if (!BCrypt.Net.BCrypt.Verify(
                    request.CurrentPassword,
                    user.PasswordHash))
            {
                return BadRequest(new
                {
                    message = "Current password is incorrect."
                });
            }

            if (string.IsNullOrWhiteSpace(request.NewPassword) ||
                request.NewPassword.Length < 6)
            {
                return BadRequest(new
                {
                    message =
                        "New password must contain at least 6 characters."
                });
            }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(
                request.NewPassword
            );

            await _db.SaveChangesAsync();

            return Ok(new
            {
                message = "Password changed successfully."
            });
        }

        private int? GetUserId()
        {
            var value = User.FindFirstValue(
                ClaimTypes.NameIdentifier
            );

            return int.TryParse(value, out var id)
                ? id
                : null;
        }
    }

    public class UpdateClientProfileRequest
    {
        public string FirstName { get; set; } = "";

        public string? LastName { get; set; }

        public string Email { get; set; } = "";

        public string? Phone { get; set; }
    }

    public class ChangeClientPasswordRequest
    {
        public string CurrentPassword { get; set; } = "";

        public string NewPassword { get; set; } = "";
    }
}