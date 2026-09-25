using System.Security.Cryptography;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.DTOs;
using NexaBook.Api.Models;
using NexaBook.Api.Services;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly TokenService _tokens;

        public AuthController(
            AppDbContext db,
            TokenService tokens)
        {
            _db = db;
            _tokens = tokens;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login(
            LoginRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new
                {
                    message = "Email and password are required."
                });
            }

            var email = NormalizeEmail(request.Email);

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user is null ||
                !BCrypt.Net.BCrypt.Verify(
                    request.Password,
                    user.PasswordHash))
            {
                return Unauthorized(new
                {
                    message = "Invalid email or password."
                });
            }

            return Ok(CreateAuthResponse(user));
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(
            RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.FirstName) ||
                string.IsNullOrWhiteSpace(request.LastName) ||
                string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Password))
            {
                return BadRequest(new
                {
                    message = "Please fill in all required fields."
                });
            }

            if (request.Password.Length < 6)
            {
                return BadRequest(new
                {
                    message =
                        "Password must contain at least 6 characters."
                });
            }

            var email = NormalizeEmail(request.Email);

            var emailExists = await _db.Users
                .AnyAsync(x => x.Email == email);

            if (emailExists)
            {
                return Conflict(new
                {
                    message = "Email already exists."
                });
            }

            var user = new User
            {
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                Email = email,
                Phone = request.Phone?.Trim(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(
                    request.Password
                ),
                Role = UserRole.Client
            };

            _db.Users.Add(user);

            await _db.SaveChangesAsync();

            var customer = new Customer
            {
                UserId = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                Phone = user.Phone
            };

            _db.Customers.Add(customer);

            await _db.SaveChangesAsync();

            return Ok(CreateAuthResponse(user));
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword(
            ForgotPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new
                {
                    message = "Email is required."
                });
            }

            var email = NormalizeEmail(request.Email);

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user is null)
            {
                return Ok(new
                {
                    message =
                        "If an account exists for this email, a reset code has been sent."
                });
            }

            await InvalidatePreviousCodes(user.Id);

            var code = GenerateResetCode();

            var passwordResetCode = new PasswordResetCode
            {
                UserId = user.Id,

                CodeHash = BCrypt.Net.BCrypt.HashPassword(
                    code
                ),

                ExpiresAt = DateTime.UtcNow.AddMinutes(10),

                IsUsed = false
            };

            _db.PasswordResetCodes.Add(passwordResetCode);

            await _db.SaveChangesAsync();

            /*
             * DEVELOPMENT ONLY
             *
             * We return the code here so that the Flutter
             * password reset flow can be tested without an
             * email provider.
             *
             * Remove developmentCode before production.
             */
            return Ok(new
            {
                message = "Reset code generated.",
                developmentCode = code
            });
        }

        [HttpPost("verify-reset-code")]
        public async Task<IActionResult> VerifyResetCode(
            VerifyResetCodeRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Code))
            {
                return BadRequest(new
                {
                    message = "Email and code are required."
                });
            }

            var email = NormalizeEmail(request.Email);

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user is null)
            {
                return BadRequest(new
                {
                    message = "Invalid or expired code."
                });
            }

            var validCode = await FindValidResetCode(
                user.Id,
                request.Code.Trim()
            );

            if (validCode is null)
            {
                return BadRequest(new
                {
                    message = "Invalid or expired code."
                });
            }

            return Ok(new
            {
                message = "Code verified."
            });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword(
            ResetPasswordRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Email) ||
                string.IsNullOrWhiteSpace(request.Code) ||
                string.IsNullOrWhiteSpace(request.NewPassword))
            {
                return BadRequest(new
                {
                    message =
                        "Email, verification code and new password are required."
                });
            }

            if (request.NewPassword.Length < 6)
            {
                return BadRequest(new
                {
                    message =
                        "Password must contain at least 6 characters."
                });
            }

            var email = NormalizeEmail(request.Email);

            var user = await _db.Users
                .FirstOrDefaultAsync(x => x.Email == email);

            if (user is null)
            {
                return BadRequest(new
                {
                    message = "Invalid reset request."
                });
            }

            var validCode = await FindValidResetCode(
                user.Id,
                request.Code.Trim()
            );

            if (validCode is null)
            {
                return BadRequest(new
                {
                    message = "Invalid or expired code."
                });
            }

            user.PasswordHash =
                BCrypt.Net.BCrypt.HashPassword(
                    request.NewPassword
                );

            /*
             * Invalidate every active reset code for this user
             * after the password has successfully been changed.
             */
            var activeCodes = await _db.PasswordResetCodes
                .Where(x =>
                    x.UserId == user.Id &&
                    !x.IsUsed)
                .ToListAsync();

            foreach (var resetCode in activeCodes)
            {
                resetCode.IsUsed = true;
            }

            await _db.SaveChangesAsync();

            return Ok(new
            {
                message =
                    "Your password has been changed successfully."
            });
        }

        private async Task InvalidatePreviousCodes(
            int userId)
        {
            var oldCodes = await _db.PasswordResetCodes
                .Where(x =>
                    x.UserId == userId &&
                    !x.IsUsed)
                .ToListAsync();

            foreach (var code in oldCodes)
            {
                code.IsUsed = true;
            }
        }

        private async Task<PasswordResetCode?> FindValidResetCode(
            int userId,
            string code)
        {
            var activeCodes = await _db.PasswordResetCodes
                .Where(x =>
                    x.UserId == userId &&
                    !x.IsUsed &&
                    x.ExpiresAt > DateTime.UtcNow)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();

            foreach (var resetCode in activeCodes)
            {
                if (BCrypt.Net.BCrypt.Verify(
                    code,
                    resetCode.CodeHash))
                {
                    return resetCode;
                }
            }

            return null;
        }

        private static string GenerateResetCode()
        {
            return RandomNumberGenerator
                .GetInt32(100000, 1000000)
                .ToString();
        }

        private static string NormalizeEmail(
            string email)
        {
            return email
                .Trim()
                .ToLowerInvariant();
        }

        private AuthResponse CreateAuthResponse(
            User user)
        {
            return new AuthResponse(
                _tokens.Create(user),
                user.Id,
                $"{user.FirstName} {user.LastName}",
                user.Email,
                user.Role.ToString()
            );
        }
    }
}