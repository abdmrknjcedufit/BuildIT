using System.Text;
using System.Text.RegularExpressions;

namespace BuildIT.Services.Helpers
{
    public class ValidationHelpers
    {
        public static string CheckPasswordStrength(string password)
        {
            StringBuilder sb = new StringBuilder();

            if (password.Length < 8)
            {
                sb.AppendLine("Lozinka mora imati najmanje 8 karaktera.");
            }

            if (!(Regex.IsMatch(password, "[a-z]") && Regex.IsMatch(password, "[A-Z]")))
            {
                sb.AppendLine("Lozinka mora sadržavati najmanje jedno veliko i jedno malo slovo.");
            }

            if (!Regex.IsMatch(password, @"\d"))
            {
                sb.AppendLine("Lozinka mora sadržavati najmanje jedan broj.");
            }

            if (!Regex.IsMatch(password, @"[<>@!#$%^&*+\-=/|~]"))
            {
                sb.AppendLine("Lozinka mora sadržavati najmanje jedan specijalni karakter");
            }

            return sb.ToString().Trim();
        }

        public static string CheckPhoneNumber(string phoneNumber)
        {
            if (!Regex.IsMatch(phoneNumber, @"^\d{9,10}$"))
            {
                return "Broj telefona mora sadržavati samo cifre i biti 9 ili 10 cifara dugačak.";
            }

            return string.Empty;
        }
    }
}

