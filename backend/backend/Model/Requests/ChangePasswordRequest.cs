namespace BuildIT.Model.Requests
{
    public class ChangePasswordRequest
    {
        public string OldPassword { get; set; } = null!;
        public string NewPassword { get; set; } = null!;
        public string NewPasswordConfirm { get; set; } = null!;
    }
}

