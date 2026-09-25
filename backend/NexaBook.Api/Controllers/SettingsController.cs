//using Microsoft.AspNetCore.Authorization;using Microsoft.AspNetCore.Mvc;using Microsoft.EntityFrameworkCore;using NexaBook.Api.Data;using NexaBook.Api.Models;
//namespace NexaBook.Api.Controllers;[ApiController,Route("api/settings"),Authorize]public class SettingsController(AppDbContext db):ControllerBase{[HttpGet]public async Task<IActionResult>Get()=>Ok(await db.BusinessSettings.FirstAsync());[HttpPut,Authorize(Roles="Owner,Manager")]public async Task<IActionResult>Update(BusinessSetting x){var s=await db.BusinessSettings.FirstAsync();s.BusinessName=x.BusinessName;s.Phone=x.Phone;s.Email=x.Email;s.Currency=x.Currency;s.TaxRate=x.TaxRate;s.CancellationHours=x.CancellationHours;await db.SaveChangesAsync();return Ok(s);}}
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Data;
using NexaBook.Api.Models;

namespace NexaBook.Api.Controllers
{
    [ApiController]
    [Route("api/settings")]
    [Authorize]
    public class SettingsController : ControllerBase
    {
        private readonly AppDbContext _db;

        public SettingsController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> Get()
        {
            var settings = await _db.BusinessSettings
                .AsNoTracking()
                .FirstOrDefaultAsync();

            if (settings == null)
            {
                return Ok(new
                {
                    businessName = "",
                    phone = "",
                    email = "",
                    currency = "EUR",
                    taxRate = 0,
                    cancellationHours = 24
                });
            }

            return Ok(settings);
        }

        [HttpPut]
        [Authorize(Roles = "Owner,Manager")]
        public async Task<IActionResult> Update(
            [FromBody] UpdateBusinessSettingsRequest request)
        {
            var settings = await _db.BusinessSettings
                .FirstOrDefaultAsync();

            if (settings == null)
            {
                settings = new BusinessSetting();

                _db.BusinessSettings.Add(settings);
            }

            settings.BusinessName = request.BusinessName.Trim();
            settings.Phone = request.Phone?.Trim();
            settings.Email = request.Email?.Trim();
            settings.Currency = request.Currency.Trim();
            settings.TaxRate = request.TaxRate;
            settings.CancellationHours = request.CancellationHours;

            await _db.SaveChangesAsync();

            return Ok(settings);
        }
    }

    public class UpdateBusinessSettingsRequest
    {
        public string BusinessName { get; set; } = string.Empty;

        public string? Phone { get; set; }

        public string? Email { get; set; }

        public string Currency { get; set; } = "EUR";

        public decimal TaxRate { get; set; }

        public int CancellationHours { get; set; }
    }
}