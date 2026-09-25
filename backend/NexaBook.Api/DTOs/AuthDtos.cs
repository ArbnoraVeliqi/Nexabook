namespace NexaBook.Api.DTOs
{
    public record LoginRequest(
        string Email,
        string Password
    );

    public record RegisterRequest(
        string FirstName,
        string LastName,
        string Email,
        string Password,
        string? Phone
    );

    public record AuthResponse(
        string Token,
        int UserId,
        string FullName,
        string Email,
        string Role
    );
}