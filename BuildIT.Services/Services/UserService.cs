using BuildIT.Model;
using BuildIT.Model.Models;
using BuildIT.Model.Requests;
using BuildIT.Model.SearchObjects;
using BuildIT.Services.Database;
using BuildIT.Services.Helpers;
using BuildIT.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace BuildIT.Services.Services
{
    public class UserService : BaseCRUDService<Model.Models.User, UserSearchObject, Database.User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly IEmailService _emailService;
        private readonly ISmsService _smsService;
        private readonly IConfiguration _configuration;

        public UserService(BuildITDbContext context, IMapper mapper, IEmailService emailService, ISmsService smsService, IConfiguration configuration) : base(context, mapper)
        {
            _emailService = emailService;
            _smsService = smsService;
            _configuration = configuration;
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
                    throw new UserException(phoneValidationResult);
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
                    throw new UserException(phoneError);
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

            if (request.Address != null)
                entity.Address = request.Address;

            if (request.CityId.HasValue)
            {
                var cityExists = Context.Cities.Any(c => c.Id == request.CityId.Value);
                if (!cityExists)
                    throw new UserException("Grad nije pronađen.");
                entity.CityId = request.CityId.Value;
            }

            if (request.PostalCode != null)
                entity.PostalCode = request.PostalCode;

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

            if (entity == null)
            {
                throw new UserException("Nevažeće korisničko ime ili lozinka");
            }

            if (!entity.IsActive)
            {
                throw new UserException("Vaš nalog je deaktiviran. Kontaktirajte administratora za više informacija.");
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

        public async Task<string> ForgotPasswordAsync(string? email, string? phone)
        {
            Database.User? user = null;

            if (!string.IsNullOrWhiteSpace(phone))
            {
                user = Context.Users.FirstOrDefault(u => u.Phone == phone);
                if (user == null)
                    throw new UserException("Korisnik sa ovim brojem telefona nije pronađen.");
            }
            else if (!string.IsNullOrWhiteSpace(email))
            {
                user = Context.Users.FirstOrDefault(u => u.Email == email);
                if (user == null)
                    throw new UserException("Korisnik sa ovom email adresom nije pronađen.");
            }
            else
            {
                throw new UserException("Morate unijeti email ili broj telefona.");
            }

            if (!user.IsActive)
                throw new UserException("Korisnički nalog je deaktiviran.");

            if (string.IsNullOrWhiteSpace(user.Phone))
                throw new UserException("Korisnik nema unesen broj telefona. Kontaktirajte administratora.");

            var newPassword = GenerateRandomPassword();
            var salt = HashGenerator.GenerateSalt();
            var hash = HashGenerator.GenerateHash(salt, newPassword);

            user.PasswordSalt = salt;
            user.PasswordHash = hash;
            Context.SaveChanges();

            await _smsService.SendPasswordResetSmsAsync(user.Phone, newPassword);

            return "Nova lozinka je poslana na vaš broj telefona.";
        }

        public Task<string> ChangePasswordAsync(int userId, string oldPassword, string newPassword, string newPasswordConfirm)
        {
            var user = Context.Users.FirstOrDefault(u => u.Id == userId);
            
            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            if (!user.IsActive)
                throw new UserException("Korisnički nalog je deaktiviran.");

            var salt = user.PasswordSalt?.Trim() ?? "";
            var storedHash = user.PasswordHash?.Trim() ?? "";
            
            var oldPasswordHash = HashGenerator.GenerateHash(salt, oldPassword);
            
            if (oldPasswordHash != storedHash)
                throw new UserException("Stara lozinka nije ispravna.");

            if (newPassword != newPasswordConfirm)
                throw new UserException("Nova lozinka i potvrda lozinke se ne podudaraju.");

            var pwValidationResult = ValidationHelpers.CheckPasswordStrength(newPassword);
            if (!string.IsNullOrEmpty(pwValidationResult))
                throw new UserException(pwValidationResult);

            var newSalt = HashGenerator.GenerateSalt();
            var newHash = HashGenerator.GenerateHash(newSalt, newPassword);

            user.PasswordSalt = newSalt;
            user.PasswordHash = newHash;
            Context.SaveChanges();

            return Task.FromResult("Lozinka je uspješno promijenjena.");
        }

        public Task<bool> ResetPasswordWithTokenAsync(string token, string newPassword)
        {
            var resetToken = Context.PasswordResetTokens
                .Include(t => t.User)
                .FirstOrDefault(t => t.Token == token && !t.IsUsed);

            if (resetToken == null)
                throw new UserException("Token za reset lozinke nije validan ili je već korišten.");

            if (resetToken.ExpiresAt < DateTime.UtcNow)
                throw new UserException("Token za reset lozinke je istekao.");

            var pwValidationResult = ValidationHelpers.CheckPasswordStrength(newPassword);
            if (!string.IsNullOrEmpty(pwValidationResult))
                throw new UserException(pwValidationResult);

            var salt = HashGenerator.GenerateSalt();
            var hash = HashGenerator.GenerateHash(salt, newPassword);

            resetToken.User.PasswordSalt = salt;
            resetToken.User.PasswordHash = hash;
            resetToken.IsUsed = true;

            Context.Users.Update(resetToken.User);
            Context.PasswordResetTokens.Update(resetToken);
            Context.SaveChanges();

            return Task.FromResult(true);
        }

        public (string Username, string Password) ForgotPassword(string email)
        {
            return Task.Run(async () =>
            {
                await ForgotPasswordAsync(email, null);
                return ("", "");
            }).Result;
        }

        private string GenerateRandomPassword()
        {
            const string uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            const string lowercase = "abcdefghijklmnopqrstuvwxyz";
            const string numbers = "0123456789";
            const string symbols = "!@#$%^&*";
            const string allChars = uppercase + lowercase + numbers + symbols;

            var random = new Random();
            var password = new System.Text.StringBuilder();

            password.Append(uppercase[random.Next(uppercase.Length)]);
            password.Append(lowercase[random.Next(lowercase.Length)]);
            password.Append(numbers[random.Next(numbers.Length)]);
            password.Append(symbols[random.Next(symbols.Length)]);

            for (int i = 4; i < 12; i++)
            {
                password.Append(allChars[random.Next(allChars.Length)]);
            }

            return new string(password.ToString().OrderBy(x => random.Next()).ToArray());
        }

        public void DeleteUser(int id)
        {
            var user = Context.Users
                .Include(u => u.UserRoles)
                .FirstOrDefault(u => u.Id == id);

            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            var isAdmin = user.UserRoles.Any(ur => ur.Role != null && ur.Role.Name == "Admin");
            if (isAdmin)
                throw new UserException("Administratori se ne mogu deaktivirati.");

            user.IsActive = !user.IsActive;
            Context.Users.Update(user);
            Context.SaveChanges();
        }

        public override Model.Models.User GetById(int id)
        {
            var entity = Context.Users
                .Include(u => u.UserRoles)
                .ThenInclude(r => r.Role)
                .Include(u => u.City)
                .FirstOrDefault(u => u.Id == id);

            if (entity == null)
                throw new UserException("Korisnik nije pronađen.");

            return Mapper.Map<Model.Models.User>(entity);
        }

        public Task<string> EnableTwoFactorAsync(int userId, string method)
        {
            if (method != "Email" && method != "SMS")
                throw new UserException("Metoda 2FA mora biti 'Email' ili 'SMS'.");

            var user = Context.Users.FirstOrDefault(u => u.Id == userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            if (method == "SMS" && string.IsNullOrWhiteSpace(user.Phone))
                throw new UserException("Broj telefona je obavezan za SMS 2FA.");

            user.TwoFactorEnabled = true;
            user.TwoFactorMethod = method;

            Context.Users.Update(user);
            Context.SaveChanges();

            return Task.FromResult("Dvofaktorska autentifikacija je uspješno omogućena.");
        }

        public Task<string> DisableTwoFactorAsync(int userId)
        {
            var user = Context.Users.FirstOrDefault(u => u.Id == userId);
            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            user.TwoFactorEnabled = false;
            user.TwoFactorMethod = null;

            Context.Users.Update(user);
            Context.SaveChanges();

            return Task.FromResult("Dvofaktorska autentifikacija je uspješno onemogućena.");
        }

        public async Task<bool> GenerateTwoFactorCodeAsync(string username)
        {
            var user = Context.Users.FirstOrDefault(u => u.Username == username);
            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            if (!user.TwoFactorEnabled || string.IsNullOrWhiteSpace(user.TwoFactorMethod))
                throw new UserException("2FA nije omogućena za ovog korisnika.");

            var code = new Random().Next(100000, 999999).ToString();
            var token = new TwoFactorToken
            {
                UserId = user.Id,
                Code = code,
                Type = user.TwoFactorMethod,
                ExpiresAt = DateTime.UtcNow.AddMinutes(10),
                IsUsed = false,
                CreatedAt = DateTime.UtcNow
            };

            Context.TwoFactorTokens.Add(token);
            Context.SaveChanges();

            if (user.TwoFactorMethod == "Email")
            {
                await _emailService.SendTwoFactorCodeEmailAsync(user.Email, code);
            }
            else if (user.TwoFactorMethod == "SMS")
            {
                if (string.IsNullOrWhiteSpace(user.Phone))
                    throw new UserException("Broj telefona nije postavljen.");

                await _smsService.SendTwoFactorCodeSmsAsync(user.Phone, code);
            }

            return true;
        }

        public Task<bool> VerifyTwoFactorCodeAsync(string username, string code)
        {
            var user = Context.Users.FirstOrDefault(u => u.Username == username);
            if (user == null)
                throw new UserException("Korisnik nije pronađen.");

            var token = Context.TwoFactorTokens
                .Where(t => t.UserId == user.Id && 
                           t.Code == code && 
                           !t.IsUsed &&
                           t.Type == user.TwoFactorMethod)
                .OrderByDescending(t => t.CreatedAt)
                .FirstOrDefault();

            if (token == null)
                throw new UserException("Kod za dvofaktorsku autentifikaciju nije validan.");

            if (token.ExpiresAt < DateTime.UtcNow)
                throw new UserException("Kod za dvofaktorsku autentifikaciju je istekao.");

            token.IsUsed = true;
            Context.TwoFactorTokens.Update(token);
            Context.SaveChanges();

            return Task.FromResult(true);
        }
    }
}

