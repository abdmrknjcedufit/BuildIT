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
            if (string.IsNullOrWhiteSpace(phoneNumber))
            {
                return string.Empty;
            }

            var trimmedPhone = phoneNumber.Trim();
            
            if (!Regex.IsMatch(trimmedPhone, @"^\+387[0-9]{8,10}$"))
            {
                return "Broj telefona mora počinjati sa +387 i imati 8 do 10 cifara bez znakova između (npr. +38761123456).";
            }

            return string.Empty;
        }
    }
}

