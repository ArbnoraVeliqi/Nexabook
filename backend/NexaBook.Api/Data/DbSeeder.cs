//using NexaBook.Api.Models; using Microsoft.EntityFrameworkCore;
//namespace NexaBook.Api.Data;
//public static class DbSeeder { public static async Task SeedAsync(AppDbContext db){ if(await db.Users.AnyAsync()) return;
// var owner=new User{FirstName="Arta",LastName="Berisha",Email="owner@nexabook.dev",PasswordHash=BCrypt.Net.BCrypt.HashPassword("Demo123!"),Role=UserRole.Owner};
// var staffUser=new User{FirstName="Leon",LastName="Krasniqi",Email="staff@nexabook.dev",PasswordHash=BCrypt.Net.BCrypt.HashPassword("Demo123!"),Role=UserRole.Staff};
// var clientUser=new User{FirstName="Elira",LastName="Hoxha",Email="client@nexabook.dev",PasswordHash=BCrypt.Net.BCrypt.HashPassword("Demo123!"),Role=UserRole.Client}; db.Users.AddRange(owner,staffUser,clientUser); await db.SaveChangesAsync();
// var cat1=new ServiceCategory{Name="Hair"}; var cat2=new ServiceCategory{Name="Beauty"}; db.ServiceCategories.AddRange(cat1,cat2); await db.SaveChangesAsync();
// var services=new[]{new Service{Name="Haircut & Styling",CategoryId=cat1.Id,Price=25,DurationMinutes=45,RequiresDeposit=true,DepositAmount=5},new Service{Name="Hair Coloring",CategoryId=cat1.Id,Price=55,DurationMinutes=120,RequiresDeposit=true,DepositAmount=15},new Service{Name="Facial Treatment",CategoryId=cat2.Id,Price=40,DurationMinutes=60},new Service{Name="Manicure",CategoryId=cat2.Id,Price=20,DurationMinutes=45}}; db.Services.AddRange(services);
// var staff=new StaffProfile{UserId=staffUser.Id,JobTitle="Senior Stylist",CommissionPercent=20}; db.StaffProfiles.Add(staff);
// var customer=new Customer{UserId=clientUser.Id,FirstName=clientUser.FirstName,LastName=clientUser.LastName,Email=clientUser.Email,Phone="+383 44 000 000"}; db.Customers.Add(customer); db.BusinessSettings.Add(new BusinessSetting{BusinessName="Nexa Studio",Email="hello@nexastudio.dev",Phone="+383 38 000 000",TaxRate=18}); await db.SaveChangesAsync();
// foreach(var s in services) db.StaffServices.Add(new StaffService{StaffProfileId=staff.Id,ServiceId=s.Id}); foreach(var d in Enum.GetValues<DayOfWeek>().Where(d=>d!=DayOfWeek.Sunday)) db.WorkSchedules.Add(new WorkSchedule{StaffProfileId=staff.Id,DayOfWeek=d,StartTime=new TimeSpan(9,0,0),EndTime=new TimeSpan(17,0,0)});
// for(int i=0;i<18;i++){var start=DateTime.Today.AddDays(i%8-2).AddHours(9+(i%7)); var svc=services[i%services.Length]; db.Appointments.Add(new Appointment{Reference=$"NB-{DateTime.Now:yyyy}-{1001+i}",CustomerId=customer.Id,ServiceId=svc.Id,StaffProfileId=staff.Id,StartAt=start,EndAt=start.AddMinutes(svc.DurationMinutes),Status=i%5==0?AppointmentStatus.Completed:AppointmentStatus.Confirmed,PaymentStatus=i%3==0?PaymentStatus.Paid:PaymentStatus.Pending,TotalAmount=svc.Price,DepositAmount=i%3==0?svc.DepositAmount:0}); }
// db.Expenses.AddRange(new Expense{Category="Supplies",Description="Professional salon supplies",Amount=145,ExpenseDate=DateTime.Today.AddDays(-4),Vendor="Beauty Supply"},new Expense{Category="Utilities",Description="Monthly utilities",Amount=90,ExpenseDate=DateTime.Today.AddDays(-8)}); await db.SaveChangesAsync(); }
//}
using Microsoft.EntityFrameworkCore;
using NexaBook.Api.Models;

namespace NexaBook.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        if (await db.Users.AnyAsync())
        {
            return;
        }

        var owner = new User
        {
            FirstName = "Arta",
            LastName = "Berisha",
            Email = "owner@nexabook.dev",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Demo123!"),
            Role = UserRole.Owner
        };

        var staffUser = new User
        {
            FirstName = "Leon",
            LastName = "Krasniqi",
            Email = "staff@nexabook.dev",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Demo123!"),
            Role = UserRole.Staff
        };

        var clientUser = new User
        {
            FirstName = "Elira",
            LastName = "Hoxha",
            Email = "client@nexabook.dev",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("Demo123!"),
            Role = UserRole.Client
        };

        db.Users.AddRange(
            owner,
            staffUser,
            clientUser
        );

        await db.SaveChangesAsync();

        var hairCategory = new ServiceCategory
        {
            Name = "Hair"
        };

        var beautyCategory = new ServiceCategory
        {
            Name = "Beauty"
        };

        db.ServiceCategories.AddRange(
            hairCategory,
            beautyCategory
        );

        await db.SaveChangesAsync();

        var services = new[]
        {
            new Service
            {
                Name = "Haircut & Styling",
                CategoryId = hairCategory.Id,
                Price = 25,
                DurationMinutes = 45,
                RequiresDeposit = true,
                DepositAmount = 5
            },

            new Service
            {
                Name = "Hair Coloring",
                CategoryId = hairCategory.Id,
                Price = 55,
                DurationMinutes = 120,
                RequiresDeposit = true,
                DepositAmount = 15
            },

            new Service
            {
                Name = "Facial Treatment",
                CategoryId = beautyCategory.Id,
                Price = 40,
                DurationMinutes = 60,
                RequiresDeposit = false,
                DepositAmount = 0
            },

            new Service
            {
                Name = "Manicure",
                CategoryId = beautyCategory.Id,
                Price = 20,
                DurationMinutes = 45,
                RequiresDeposit = false,
                DepositAmount = 0
            }
        };

        db.Services.AddRange(services);

        var staff = new StaffProfile
        {
            UserId = staffUser.Id,
            JobTitle = "Senior Stylist",
            CommissionPercent = 20,
            AcceptsBookings = true
        };

        db.StaffProfiles.Add(staff);

        var customer = new Customer
        {
            UserId = clientUser.Id,
            FirstName = clientUser.FirstName,
            LastName = clientUser.LastName,
            Email = clientUser.Email,
            Phone = "+383 44 000 000"
        };

        db.Customers.Add(customer);

        var settings = new BusinessSetting
        {
            BusinessName = "Nexa Studio",
            Email = "hello@nexastudio.dev",
            Phone = "+383 38 000 000",
            TaxRate = 18
        };

        db.BusinessSettings.Add(settings);

        await db.SaveChangesAsync();

        foreach (var service in services)
        {
            db.StaffServices.Add(
                new StaffService
                {
                    StaffProfileId = staff.Id,
                    ServiceId = service.Id
                }
            );
        }

        var workingDays = Enum
            .GetValues<DayOfWeek>()
            .Where(
                day => day != DayOfWeek.Sunday
            );

        foreach (var day in workingDays)
        {
            db.WorkSchedules.Add(
                new WorkSchedule
                {
                    StaffProfileId = staff.Id,
                    DayOfWeek = day,
                    StartTime = new TimeSpan(
                        9,
                        0,
                        0
                    ),
                    EndTime = new TimeSpan(
                        17,
                        0,
                        0
                    )
                }
            );
        }

        await db.SaveChangesAsync();

        var appointments = new List<Appointment>();

        for (var i = 0; i < 18; i++)
        {
            var start = DateTime.Today
                .AddDays(i % 8 - 2)
                .AddHours(9 + i % 7);

            var service =
                services[i % services.Length];

            var appointment = new Appointment
            {
                Reference =
                    $"NB-{DateTime.Now:yyyy}-{1001 + i}",

                CustomerId =
                    customer.Id,

                ServiceId =
                    service.Id,

                StaffProfileId =
                    staff.Id,

                StartTime =
                    start,

                EndTime =
                    start.AddMinutes(
                        service.DurationMinutes
                    ),

                Status =
                    i % 5 == 0
                        ? AppointmentStatus.Completed
                        : i % 4 == 0
                            ? AppointmentStatus.Pending
                            : AppointmentStatus.Confirmed,

                TotalAmount =
                    service.Price,

                Notes =
                    GetAppointmentNote(i),

                Source =
                    i % 4 == 0
                        ? "ClientApp"
                        : "Business",

                CreatedAt =
                    DateTime.UtcNow.AddDays(-i)
            };

            appointments.Add(appointment);

            db.Appointments.Add(appointment);
        }

        await db.SaveChangesAsync();

        for (var i = 0; i < appointments.Count; i++)
        {
            var appointment = appointments[i];

            var service =
                services[i % services.Length];

            if (i % 3 == 0)
            {
                db.Payments.Add(
                    new Payment
                    {
                        AppointmentId =
                            appointment.Id,

                        Amount =
                            appointment.TotalAmount,

                        Method =
                            i % 2 == 0
                                ? PaymentMethod.Card
                                : PaymentMethod.Cash,

                        Type =
                            PaymentType.Payment,

                        Notes =
                            "Full payment",

                        CreatedAt =
                            DateTime.UtcNow.AddDays(
                                -(i % 5)
                            )
                    }
                );

                continue;
            }

            if (service.RequiresDeposit &&
                service.DepositAmount > 0)
            {
                db.Payments.Add(
                    new Payment
                    {
                        AppointmentId =
                            appointment.Id,

                        Amount =
                            service.DepositAmount,

                        Method =
                            PaymentMethod.Card,

                        Type =
                            PaymentType.Advance,

                        Notes =
                            "Booking deposit",

                        CreatedAt =
                            DateTime.UtcNow.AddDays(
                                -(i % 4)
                            )
                    }
                );
            }
        }

        db.Expenses.AddRange(
            new Expense
            {
                Category = "Supplies",
                Description =
                    "Professional salon supplies",
                Amount = 145,
                ExpenseDate =
                    DateTime.Today.AddDays(-4),
                Vendor =
                    "Beauty Supply"
            },

            new Expense
            {
                Category = "Utilities",
                Description =
                    "Monthly utilities",
                Amount = 90,
                ExpenseDate =
                    DateTime.Today.AddDays(-8)
            }
        );

        await db.SaveChangesAsync();
    }

    private static string GetAppointmentNote(int index)
    {
        return (index % 4) switch
        {
            0 => "First visit",
            1 => "Regular client",
            2 => "Prefers afternoon appointments",
            _ => "No special requests"
        };
    }
}