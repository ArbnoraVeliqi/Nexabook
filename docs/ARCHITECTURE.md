# Architecture

Both Flutter applications communicate with the same ASP.NET Core REST API. The API owns authentication, authorization, validation and business rules. EF Core maps the domain to SQL Server.

`Flutter Client -> REST API -> EF Core -> SQL Server`

`Flutter Business -> REST API -> EF Core -> SQL Server`

Roles: Owner, Manager, Staff, Client.
