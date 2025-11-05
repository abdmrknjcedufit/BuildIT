using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Helpers;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace BuildIT.Services.Services
{
    public class UserService : BaseCRUDService<Model.Models.User, UserSearchObject, Database.User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        public UserService(BuildITDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override IQueryable<Database.User> AddFilter(UserSearchObject search, IQueryable<Database.User> query)
        {
            var filteredQuery = base.AddFilter(search, query);

            if (!string.IsNullOrWhiteSpace(search?.FTS))
            {
                var fts = search.FTS;
                filteredQuery = filteredQuery.Where(x =>
                    x.FirstName.Contains(fts) ||
                    x.LastName.Contains(fts) ||
                    x.Username.Contains(fts) ||
                    x.Email.Contains(fts));
            }

            filteredQuery = filteredQuery.Where(x =>
                !x.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == "Admin")
            );

            if (search != null && search.FromDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.BirthDate >= search.FromDate.Value);
            }

            if (search != null && search.ToDate.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.BirthDate <= search.ToDate.Value);
            }

            if (search != null && search.IsActive.HasValue)
            {
                filteredQuery = filteredQuery.Where(x => x.IsActive == search.IsActive.Value);
            }

            filteredQuery = filteredQuery.OrderByDescending(p => p.CreatedAt);

            return filteredQuery;
        }

        public override void BeforeInsert(UserInsertRequest request, Database.User entity)
        {
            if (Context.Users.Any(u => u.Username.ToLower() == request.Username.ToLower()))
                throw new UserException("Korisničko ime je već zauzeto");

            if (Context.Users.Any(u => u.Email == request.Email))
                throw new UserException("Email je već u upotrebi");

            var pwValidationResult = ValidationHelpers.CheckPasswordStrength(request.Password);
            if (!string.IsNullOrEmpty(pwValidationResult))
                throw new UserException(pwValidationResult);

            if (!string.IsNullOrEmpty(request.Phone))
            {
                var phoneValidationResult = ValidationHelpers.CheckPhoneNumber(request.Phone);
                if (!string.IsNullOrEmpty(phoneValidationResult))
                    throw new UserException("Nevažeći broj telefona");
            }

            if (request.Password != request.PasswordConfirm)
                throw new UserException("Lozinka i potvrda lozinke se ne podudaraju");

            if (string.IsNullOrWhiteSpace(request.UserType))
                request.UserType = "Individual";

            if (request.UserType != "Individual" && request.UserType != "Company")
                throw new UserException("UserType mora biti 'Individual' ili 'Company'");

            entity.UserType = request.UserType;
            entity.PasswordSalt = HashGenerator.GenerateSalt();
            entity.PasswordHash = HashGenerator.GenerateHash(entity.PasswordSalt, request.Password);
            entity.IsActive = true;

            var requestedRole = string.IsNullOrWhiteSpace(request.Role) ? "User" : request.Role;

            var role = Context.Roles.FirstOrDefault(r => r.Name == requestedRole);
            if (role == null)
                throw new Exception($"Rola '{requestedRole}' nije pronađena u bazi podataka.");

            entity.UserRoles = new List<Database.UserRole>
            {
                new Database.UserRole { RoleId = role.Id }
            };
        }

        public override void BeforeUpdate(UserUpdateRequest request, Database.User entity)
        {
            base.BeforeUpdate(request, entity);

            if (entity == null)
                throw new UserException("Korisnik nije pronađen.");

            if (!entity.IsActive)
                throw new UserException("Nije moguće ažurirati podatke neaktivnog korisnika.");

            if (!string.IsNullOrWhiteSpace(request.Phone))
            {
                var phoneError = ValidationHelpers.CheckPhoneNumber(request.Phone);
                if (!string.IsNullOrEmpty(phoneError))
                    throw new UserException("Nevažeći broj telefona");
            }

            if (!string.IsNullOrWhiteSpace(request.NewPassword))
            {
                if (string.IsNullOrWhiteSpace(request.CurrentPassword))
                    throw new UserException("Trenutna lozinka je obavezna za promjenu lozinke.");

                var isCurrentPasswordValid = entity.PasswordHash ==
                    HashGenerator.GenerateHash(entity.PasswordSalt, request.CurrentPassword);

                if (!isCurrentPasswordValid)
                    throw new UserException("Trenutna lozinka je netačna.");

                var pwError = ValidationHelpers.CheckPasswordStrength(request.NewPassword);
                if (!string.IsNullOrEmpty(pwError))
                    throw new UserException(pwError);

                if (request.NewPassword != request.NewPasswordConfirm)
                    throw new UserException("Nova lozinka i potvrda se ne podudaraju.");

                entity.PasswordSalt = HashGenerator.GenerateSalt();
                entity.PasswordHash = HashGenerator.GenerateHash(entity.PasswordSalt, request.NewPassword);
            }

            if (!string.IsNullOrWhiteSpace(request.FirstName))
                entity.FirstName = request.FirstName;

            if (!string.IsNullOrWhiteSpace(request.LastName))
                entity.LastName = request.LastName;

            if (!string.IsNullOrWhiteSpace(request.Email))
                entity.Email = request.Email;

            if (!string.IsNullOrWhiteSpace(request.Phone))
                entity.Phone = request.Phone;

            if (request.BirthDate.HasValue)
                entity.BirthDate = request.BirthDate.Value;
        }

        public async Task<List<Model.Models.Role>> GetUserRolesAsync(int id)
        {
            var roles = await Context.UserRoles
                .Where(ur => ur.UserId == id)
                .Select(ur => ur.Role)
                .ToListAsync();

            return Mapper.Map<List<Model.Models.Role>>(roles);
        }

        public Model.Models.User Login(string username, string password)
        {
            if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
            {
                throw new UserException("Korisničko ime i lozinka su obavezni");
            }

            var entity = Context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(r => r.Role)
                .FirstOrDefault(x => x.Username == username);

            if (entity == null || !entity.IsActive)
            {
                throw new UserException("Nevažeće korisničko ime ili lozinka");
            }

            if (string.IsNullOrEmpty(entity.PasswordSalt) || string.IsNullOrEmpty(entity.PasswordHash))
            {
                throw new UserException("Nevažeće korisničko ime ili lozinka");
            }

            var salt = entity.PasswordSalt.Trim();
            var storedHash = entity.PasswordHash.Trim();
            
            var hash = HashGenerator.GenerateHash(salt, password);

            if (hash != storedHash)
            {
                throw new UserException("Nevažeće korisničko ime ili lozinka");
            }

            return Mapper.Map<Model.Models.User>(entity);
        }

        public Model.Models.User ToggleActiveStatus(int userId, UserToggleActiveRequest request)
        {
            var user = Context.Users
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .FirstOrDefault(u => u.Id == userId);

            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            bool isAdmin = user.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == "Admin");

            if (!request.IsActive && isAdmin)
                throw new UserException("Nije moguće deaktivirati korisnika sa Admin rolom.");

            user.IsActive = request.IsActive;
            Context.SaveChanges();

            return Mapper.Map<Model.Models.User>(user);
        }

        public (string Username, string Password) ResetPassword(int userId, string newPassword)
        {
            var user = Context.Users.FirstOrDefault(u => u.Id == userId);

            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            var pwValidationResult = ValidationHelpers.CheckPasswordStrength(newPassword);
            if (!string.IsNullOrEmpty(pwValidationResult))
                throw new UserException(pwValidationResult);

            var salt = HashGenerator.GenerateSalt();
            var hash = HashGenerator.GenerateHash(salt, newPassword);

            user.PasswordSalt = salt;
            user.PasswordHash = hash;

            Context.Users.Update(user);
            Context.SaveChanges();

            return (user.Username, newPassword);
        }
    }
}

