using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;

namespace BuildIT.Services.Interfaces
{
    public interface IUserService : ICRUDService<User, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Task<List<Role>> GetUserRolesAsync(int id);
        User Login(string username, string password);
        User ToggleActiveStatus(int userId, UserToggleActiveRequest request);
        (string Username, string Password) ResetPassword(int userId, string newPassword);
        (string Username, string Password) ForgotPassword(string email);
        Task<string> ForgotPasswordAsync(string? email, string? phone);
        Task<string> ChangePasswordAsync(int userId, string oldPassword, string newPassword, string newPasswordConfirm);
        Task<bool> ResetPasswordWithTokenAsync(string token, string newPassword);
        Task<string> EnableTwoFactorAsync(int userId, string method);
        Task<string> DisableTwoFactorAsync(int userId);
        Task<bool> GenerateTwoFactorCodeAsync(string username);
        Task<bool> VerifyTwoFactorCodeAsync(string username, string code);
        void DeleteUser(int id);
    }
}

