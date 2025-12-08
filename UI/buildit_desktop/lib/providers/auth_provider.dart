class AuthProvider {
  static String? username;
  static String? password;
  static int? id;
  static String? userType;

  static void logout() {
    username = null;
    password = null;
    id = null;
    userType = null;
  }
}

