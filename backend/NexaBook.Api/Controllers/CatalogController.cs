//using Microsoft.AspNetCore.Authorization;
//using Microsoft.AspNetCore.Mvc;
//using Microsoft.EntityFrameworkCore;
//using NexaBook.Api.Data;
//using NexaBook.Api.Models;

//namespace NexaBook.Api.Controllers
//{
//    [ApiController]
//    [Route("api/catalog")]
//    public class CatalogController : ControllerBase
//    {
//        private readonly AppDbContext _db;

//        public CatalogController(AppDbContext db)
//        {
//            _db = db;
//        }


//        [HttpGet("services")]
//        public async Task<IActionResult> GetServices()
//        {
//            var services = await _db.Services
//                .AsNoTracking()
//                .Include(x => x.Category)
//                .OrderBy(x => x.Name)
//                .Select(x => new
//                {
//                    x.Id,
//                    x.Name,
//                    x.Description,
//                    x.Price,
//                    x.DurationMinutes,
//                    x.CategoryId,
//                    CategoryName = x.Category != null
//                        ? x.Category.Name
//                        : null,
//                    x.RequiresDeposit,
//                    x.DepositAmount,
//                    x.IsActive
//                })
//                .ToListAsync();

//            return Ok(services);
//        }

//        [HttpPost("services")]
//        [Authorize(Roles = "Owner,Manager")]
//        public async Task<IActionResult> AddService(
//            [FromBody] SaveServiceRequest request)
//        {
//            if (string.IsNullOrWhiteSpace(request.Name))
//            {
//                return BadRequest("Service name is required.");
//            }

//            if (request.Price < 0)
//            {
//                return BadRequest("Price cannot be negative.");
//            }

//            if (request.DurationMinutes <= 0)
//            {
//                return BadRequest("Duration must be greater than zero.");
//            }

//            var categoryExists = await _db.ServiceCategories
//                .AnyAsync(x => x.Id == request.CategoryId);

//            if (!categoryExists)
//            {
//                return BadRequest("Selected category does not exist.");
//            }

//            if (request.RequiresDeposit &&
//                request.DepositAmount < 0)
//            {
//                return BadRequest("Deposit cannot be negative.");
//            }

//            if (request.RequiresDeposit &&
//                request.DepositAmount > request.Price)
//            {
//                return BadRequest(
//                    "Deposit cannot be greater than service price.");
//            }

//            var service = new Service
//            {
//                Name = request.Name.Trim(),
//                Description = request.Description?.Trim(),
//                Price = request.Price,
//                DurationMinutes = request.DurationMinutes,
//                CategoryId = request.CategoryId,
//                RequiresDeposit = request.RequiresDeposit,
//                DepositAmount = request.RequiresDeposit
//                    ? request.DepositAmount
//                    : 0,
//                IsActive = request.IsActive
//            };

//            _db.Services.Add(service);

//            await _db.SaveChangesAsync();

//            return Ok(service);
//        }

//        [HttpPut("services/{id:int}")]
//        [Authorize(Roles = "Owner,Manager")]
//        public async Task<IActionResult> UpdateService(
//            int id,
//            [FromBody] SaveServiceRequest request)
//        {
//            var service = await _db.Services.FindAsync(id);

//            if (service == null)
//            {
//                return NotFound();
//            }

//            if (string.IsNullOrWhiteSpace(request.Name))
//            {
//                return BadRequest("Service name is required.");
//            }

//            if (request.Price < 0)
//            {
//                return BadRequest("Price cannot be negative.");
//            }

//            if (request.DurationMinutes <= 0)
//            {
//                return BadRequest("Duration must be greater than zero.");
//            }

//            var categoryExists = await _db.ServiceCategories
//                .AnyAsync(x => x.Id == request.CategoryId);

//            if (!categoryExists)
//            {
//                return BadRequest("Selected category does not exist.");
//            }

//            if (request.RequiresDeposit &&
//                request.DepositAmount < 0)
//            {
//                return BadRequest("Deposit cannot be negative.");
//            }

//            if (request.RequiresDeposit &&
//                request.DepositAmount > request.Price)
//            {
//                return BadRequest(
//                    "Deposit cannot be greater than service price.");
//            }

//            service.Name = request.Name.Trim();
//            service.Description = request.Description?.Trim();
//            service.Price = request.Price;
//            service.DurationMinutes = request.DurationMinutes;
//            service.CategoryId = request.CategoryId;
//            service.RequiresDeposit = request.RequiresDeposit;
//            service.DepositAmount = request.RequiresDeposit
//                ? request.DepositAmount
//                : 0;
//            service.IsActive = request.IsActive;

//            await _db.SaveChangesAsync();

//            return Ok(service);
//        }



//        [HttpGet("services")]
//        public async Task<IActionResult> Services()
//        {
//            var services = await _db.Services
//                .AsNoTracking()
//                .Include(x => x.Category)
//                .Where(x => x.IsActive)
//                .OrderBy(x => x.Name)
//                .ToListAsync();

//            return Ok(services);
//        }

//        [HttpPost("services")]
//        [Authorize(Roles = "Owner,Manager")]
//        public async Task<IActionResult> AddService(
//            Service service)
//        {
//            if (string.IsNullOrWhiteSpace(service.Name))
//            {
//                return BadRequest(new
//                {
//                    message = "Service name is required."
//                });
//            }

//            if (service.Price < 0)
//            {
//                return BadRequest(new
//                {
//                    message = "Service price cannot be negative."
//                });
//            }

//            if (service.DurationMinutes <= 0)
//            {
//                return BadRequest(new
//                {
//                    message = "Service duration must be greater than zero."
//                });
//            }

//            var categoryExists =
//                await _db.ServiceCategories.AnyAsync(
//                    x => x.Id == service.CategoryId
//                );

//            if (!categoryExists)
//            {
//                return BadRequest(new
//                {
//                    message = "Service category was not found."
//                });
//            }

//            service.Name = service.Name.Trim();

//            _db.Services.Add(service);

//            await _db.SaveChangesAsync();

//            return Ok(service);
//        }

//        [HttpGet("categories")]
//        public async Task<IActionResult> Categories()
//        {
//            var categories = await _db.ServiceCategories
//                .AsNoTracking()
//                .Where(x => x.IsActive)
//                .OrderBy(x => x.Name)
//                .ToListAsync();

//            return Ok(categories);
//        }

//        [HttpGet("staff")]
//        public async Task<IActionResult> Staff()
//        {
//            var staff = await _db.StaffProfiles
//                .AsNoTracking()
//                .Include(x => x.User)
//                .Where(x =>
//                    x.AcceptsBookings &&
//                    x.User != null &&
//                    x.User.IsActive)
//                .Select(x => new
//                {
//                    x.Id,

//                    Name = (
//                        x.User!.FirstName +
//                        " " +
//                        x.User.LastName
//                    ).Trim(),

//                    x.JobTitle,
//                    x.CommissionPercent,
//                    x.AcceptsBookings
//                })
//                .OrderBy(x => x.Name)
//                .ToListAsync();

//            return Ok(staff);
//        }

//        [HttpGet("availability")]
//        public async Task<IActionResult> Availability(
//            int staffId,
//            int serviceId,
//            DateTime date)
//        {
//            var service = await _db.Services
//                .AsNoTracking()
//                .FirstOrDefaultAsync(x =>
//                    x.Id == serviceId &&
//                    x.IsActive
//                );

//            if (service is null)
//            {
//                return NotFound(new
//                {
//                    message = "Service was not found."
//                });
//            }

//            var staff = await _db.StaffProfiles
//                .AsNoTracking()
//                .Include(x => x.User)
//                .FirstOrDefaultAsync(x =>
//                    x.Id == staffId
//                );

//            if (staff is null)
//            {
//                return NotFound(new
//                {
//                    message = "Team member was not found."
//                });
//            }

//            if (!staff.AcceptsBookings)
//            {
//                return Ok(Array.Empty<DateTime>());
//            }

//            if (staff.User == null ||
//                !staff.User.IsActive)
//            {
//                return Ok(Array.Empty<DateTime>());
//            }

//            var canProvideService =
//                await _db.StaffServices
//                    .AsNoTracking()
//                    .AnyAsync(x =>
//                        x.StaffProfileId == staffId &&
//                        x.ServiceId == serviceId
//                    );

//            if (!canProvideService)
//            {
//                return Ok(Array.Empty<DateTime>());
//            }

//            var schedule = await _db.WorkSchedules
//                .AsNoTracking()
//                .FirstOrDefaultAsync(x =>
//                    x.StaffProfileId == staffId &&
//                    x.DayOfWeek == date.DayOfWeek &&
//                    x.IsWorking
//                );

//            if (schedule is null)
//            {
//                return Ok(Array.Empty<DateTime>());
//            }

//            var dayStart = date.Date;
//            var dayEnd = dayStart.AddDays(1);

//            var bookings = await _db.Appointments
//                .AsNoTracking()
//                .Where(x =>
//                    x.StaffProfileId == staffId &&
//                    x.StartTime >= dayStart &&
//                    x.StartTime < dayEnd &&
//                    x.Status != AppointmentStatus.Cancelled &&
//                    x.Status != AppointmentStatus.NoShow
//                )
//                .Select(x => new
//                {
//                    x.StartTime,
//                    x.EndTime
//                })
//                .ToListAsync();

//            var workingStart =
//                date.Date + schedule.StartTime;

//            var workingEnd =
//                date.Date + schedule.EndTime;

//            var slots = new List<DateTime>();

//            var slotDuration =
//                TimeSpan.FromMinutes(
//                    service.DurationMinutes
//                );

//            var slotInterval =
//                TimeSpan.FromMinutes(30);

//            for (
//                var slotStart = workingStart;
//                slotStart + slotDuration <= workingEnd;
//                slotStart += slotInterval)
//            {
//                var slotEnd =
//                    slotStart + slotDuration;

//                var hasConflict = bookings.Any(
//                    booking =>
//                        slotStart < booking.EndTime &&
//                        slotEnd > booking.StartTime
//                );

//                if (hasConflict)
//                {
//                    continue;
//                }

//                // Do not return past times for today.
//                if (date.Date == DateTime.Today &&
//                    slotStart <= DateTime.Now)
//                {
//                    continue;
//                }

//                slots.Add(slotStart);
//            }

//            return Ok(slots);
//        }
//    }
//    public class SaveServiceRequest
//    {
//        public string Name { get; set; } = string.Empty;

//        public string? Description { get; set; }

//        public decimal Price { get; set; }

//        public int DurationMinutes { get; set; }

//        public int CategoryId { get; set; }

//        public bool RequiresDeposit { get; set; }

//        public decimal DepositAmount { get; set; }

//        public bool IsActive { get; set; } = true;
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
    [Route("api/catalog")]
    public class CatalogController : ControllerBase
    {
        private readonly AppDbContext _db;

        public CatalogController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet("services")]
        public async Task<IActionResult> GetServices()
        {
            var services = await _db.Services
                .AsNoTracking()
                .Include(x => x.Category)
                .OrderBy(x => x.Name)
                .Select(x => new
                {
                    x.Id,
                    x.Name,
                    x.Description,
                    x.Price,
                    x.DurationMinutes,
                    x.CategoryId,
                    CategoryName = x.Category != null
                        ? x.Category.Name
                        : null,
                    x.RequiresDeposit,
                    x.DepositAmount,
                    x.IsActive
                })
                .ToListAsync();

            return Ok(services);
        }

        [HttpPost("services")]
        [Authorize(Roles = "Owner,Manager")]
        public async Task<IActionResult> AddService(
            [FromBody] SaveServiceRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return BadRequest("Service name is required.");
            }

            if (request.Price < 0)
            {
                return BadRequest("Price cannot be negative.");
            }

            if (request.DurationMinutes <= 0)
            {
                return BadRequest(
                    "Duration must be greater than zero.");
            }

            var categoryExists = await _db.ServiceCategories
                .AnyAsync(x => x.Id == request.CategoryId);

            if (!categoryExists)
            {
                return BadRequest(
                    "Selected category does not exist.");
            }

            if (request.RequiresDeposit &&
                request.DepositAmount < 0)
            {
                return BadRequest(
                    "Deposit cannot be negative.");
            }

            if (request.RequiresDeposit &&
                request.DepositAmount > request.Price)
            {
                return BadRequest(
                    "Deposit cannot be greater than service price.");
            }

            var service = new Service
            {
                Name = request.Name.Trim(),
                Description = request.Description?.Trim(),
                Price = request.Price,
                DurationMinutes = request.DurationMinutes,
                CategoryId = request.CategoryId,
                RequiresDeposit = request.RequiresDeposit,
                DepositAmount = request.RequiresDeposit
                    ? request.DepositAmount
                    : 0,
                IsActive = request.IsActive
            };

            _db.Services.Add(service);

            await _db.SaveChangesAsync();

            return Ok(service);
        }

        [HttpPut("services/{id:int}")]
        [Authorize(Roles = "Owner,Manager")]
        public async Task<IActionResult> UpdateService(
            int id,
            [FromBody] SaveServiceRequest request)
        {
            var service = await _db.Services.FindAsync(id);

            if (service == null)
            {
                return NotFound();
            }

            if (string.IsNullOrWhiteSpace(request.Name))
            {
                return BadRequest(
                    "Service name is required.");
            }

            if (request.Price < 0)
            {
                return BadRequest(
                    "Price cannot be negative.");
            }

            if (request.DurationMinutes <= 0)
            {
                return BadRequest(
                    "Duration must be greater than zero.");
            }

            var categoryExists = await _db.ServiceCategories
                .AnyAsync(x => x.Id == request.CategoryId);

            if (!categoryExists)
            {
                return BadRequest(
                    "Selected category does not exist.");
            }

            if (request.RequiresDeposit &&
                request.DepositAmount < 0)
            {
                return BadRequest(
                    "Deposit cannot be negative.");
            }

            if (request.RequiresDeposit &&
                request.DepositAmount > request.Price)
            {
                return BadRequest(
                    "Deposit cannot be greater than service price.");
            }

            service.Name = request.Name.Trim();
            service.Description = request.Description?.Trim();
            service.Price = request.Price;
            service.DurationMinutes = request.DurationMinutes;
            service.CategoryId = request.CategoryId;
            service.RequiresDeposit = request.RequiresDeposit;
            service.DepositAmount = request.RequiresDeposit
                ? request.DepositAmount
                : 0;
            service.IsActive = request.IsActive;

            await _db.SaveChangesAsync();

            return Ok(service);
        }

        [HttpGet("categories")]
        public async Task<IActionResult> Categories()
        {
            var categories = await _db.ServiceCategories
                .AsNoTracking()
                .Where(x => x.IsActive)
                .OrderBy(x => x.Name)
                .ToListAsync();

            return Ok(categories);
        }

        [HttpGet("staff")]
        public async Task<IActionResult> Staff()
        {
            var staff = await _db.StaffProfiles
                .AsNoTracking()
                .Include(x => x.User)
                .Where(x =>
                    x.AcceptsBookings &&
                    x.User != null &&
                    x.User.IsActive)
                .Select(x => new
                {
                    x.Id,

                    Name = (
                        x.User!.FirstName +
                        " " +
                        x.User.LastName
                    ).Trim(),

                    x.JobTitle,
                    x.CommissionPercent,
                    x.AcceptsBookings
                })
                .OrderBy(x => x.Name)
                .ToListAsync();

            return Ok(staff);
        }

        [HttpGet("availability")]
        public async Task<IActionResult> Availability(
            int staffId,
            int serviceId,
            DateTime date)
        {
            var service = await _db.Services
                .AsNoTracking()
                .FirstOrDefaultAsync(x =>
                    x.Id == serviceId &&
                    x.IsActive);

            if (service is null)
            {
                return NotFound(new
                {
                    message = "Service was not found."
                });
            }

            var staff = await _db.StaffProfiles
                .AsNoTracking()
                .Include(x => x.User)
                .FirstOrDefaultAsync(x =>
                    x.Id == staffId);

            if (staff is null)
            {
                return NotFound(new
                {
                    message = "Team member was not found."
                });
            }

            if (!staff.AcceptsBookings)
            {
                return Ok(Array.Empty<DateTime>());
            }

            if (staff.User == null ||
                !staff.User.IsActive)
            {
                return Ok(Array.Empty<DateTime>());
            }

            var canProvideService =
                await _db.StaffServices
                    .AsNoTracking()
                    .AnyAsync(x =>
                        x.StaffProfileId == staffId &&
                        x.ServiceId == serviceId);

            if (!canProvideService)
            {
                return Ok(Array.Empty<DateTime>());
            }

            var schedule = await _db.WorkSchedules
                .AsNoTracking()
                .FirstOrDefaultAsync(x =>
                    x.StaffProfileId == staffId &&
                    x.DayOfWeek == date.DayOfWeek &&
                    x.IsWorking);

            if (schedule is null)
            {
                return Ok(Array.Empty<DateTime>());
            }

            var dayStart = date.Date;
            var dayEnd = dayStart.AddDays(1);

            var bookings = await _db.Appointments
                .AsNoTracking()
                .Where(x =>
                    x.StaffProfileId == staffId &&
                    x.StartTime >= dayStart &&
                    x.StartTime < dayEnd &&
                    x.Status != AppointmentStatus.Cancelled &&
                    x.Status != AppointmentStatus.NoShow)
                .Select(x => new
                {
                    x.StartTime,
                    x.EndTime
                })
                .ToListAsync();

            var workingStart =
                date.Date + schedule.StartTime;

            var workingEnd =
                date.Date + schedule.EndTime;

            var slots = new List<DateTime>();

            var slotDuration =
                TimeSpan.FromMinutes(
                    service.DurationMinutes);

            var slotInterval =
                TimeSpan.FromMinutes(30);

            for (
                var slotStart = workingStart;
                slotStart + slotDuration <= workingEnd;
                slotStart += slotInterval)
            {
                var slotEnd =
                    slotStart + slotDuration;

                var hasConflict = bookings.Any(
                    booking =>
                        slotStart < booking.EndTime &&
                        slotEnd > booking.StartTime);

                if (hasConflict)
                {
                    continue;
                }

                if (date.Date == DateTime.Today &&
                    slotStart <= DateTime.Now)
                {
                    continue;
                }

                slots.Add(slotStart);
            }

            return Ok(slots);
        }
    }

    public class SaveServiceRequest
    {
        public string Name { get; set; } = string.Empty;

        public string? Description { get; set; }

        public decimal Price { get; set; }

        public int DurationMinutes { get; set; }

        public int CategoryId { get; set; }

        public bool RequiresDeposit { get; set; }

        public decimal DepositAmount { get; set; }

        public bool IsActive { get; set; } = true;
    }
}