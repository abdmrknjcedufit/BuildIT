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
    }
}

