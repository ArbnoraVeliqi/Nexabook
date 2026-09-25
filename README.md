# NexaBook

NexaBook is a complete appointment and business management platform built with Flutter, ASP.NET Core and SQL Server.

The repository contains two Flutter applications that use the same REST API:

- **NexaBook Client** - customer mobile application for booking appointments, deposits, invoices and notifications.
- **NexaBook Business** - responsive management application for owners, managers and staff.
- **NexaBook API** - ASP.NET Core Web API with Entity Framework Core, JWT authentication and SQL Server.

## Main features

### Client app
- Registration and login
- Business/service discovery
- Staff and availability selection
- Appointment booking, rescheduling and cancellation
- Deposits and payment history
- Invoice history
- Notifications
- Profile management

### Business app
- KPI dashboard
- Calendar and appointments
- Customer management
- Staff, roles and permissions
- Services and categories
- Work schedules
- Payments and deposits
- Invoices
- Expenses and finance overview
- Reports and staff performance
- Notifications and business settings

## Stack
- Flutter / Dart
- ASP.NET Core (.NET 10)
- Entity Framework Core
- SQL Server
- JWT + BCrypt

## Structure
```
NexaBook/
  backend/NexaBook.Api/
  apps/nexabook_client/
  apps/nexabook_business/
  docs/
```

## Demo accounts
- Owner: `owner@nexabook.dev` / `Demo123!`
- Staff: `staff@nexabook.dev` / `Demo123!`
- Client: `client@nexabook.dev` / `Demo123!`

## Local setup
1. Update the SQL Server connection string in `backend/NexaBook.Api/appsettings.json`.
2. Run the API from Visual Studio or with `dotnet run`.
3. In each Flutter app, run `flutter pub get` and then `flutter run`.
4. Android emulator API base URL is configured as `http://10.0.2.2:5080/api`. For Windows use `http://localhost:5080/api`.

The API creates and seeds a demo database on first run for portfolio/local use. For production, replace `EnsureCreated` with EF Core migrations and move secrets to environment variables.
