import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/user_model.dart';

class UserProvider extends BaseProvider<User> {
  UserProvider() : super("User");

  @override
  User fromJson(data) {
    return User.fromJson(data);
  }

  Future<void> logout() async {
    var url = "${BaseProvider.baseUrl}User/logout";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("🔵 Sending logout request to: $url");

    var response = await http.post(uri, headers: headers);

    print("🔵 Logout response status: ${response.statusCode}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print("✅ Logout successful");
    } else {
      print("⚠️ Logout response: ${response.body}");
    }
  }

  Future<User> login(String username, String password, {String clientType = "mobile"}) async {
    var url = "${BaseProvider.baseUrl}User/login";
    var uri = Uri.parse(url);
    
    var credentials = base64Encode(utf8.encode('$username:$password'));
    
    var headers = {
      "Content-Type": "application/json",
      "X-Client-Type": clientType,
      "Authorization": "Basic $credentials",
    };

    var body = jsonEncode({"username": username, "password": password});

    print("🔵 Sending login request to: $url");
    print("🔵 Headers: $headers");
    print("🔵 Body: $body");

    var response = await http.post(uri, headers: headers, body: body);

    print("🔵 Response status: ${response.statusCode}");
    print("🔵 Response body: ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        var data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic>) {
          if (data.containsKey('user')) {
            data = data['user'];
          }
          return User.fromJson(data);
        } else {
          throw Exception("Neočekivani format odgovora");
        }
      } catch (e) {
        print("❌ Error parsing response: $e");
        throw Exception("Greška pri parsiranju odgovora: $e");
      }
    } else {
      try {
        var errorData = jsonDecode(response.body);
        String errorMessage = "Prijava neuspješna";
        
        if (errorData is Map<String, dynamic>) {
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          } else if (errorData.containsKey('errors')) {
            var errors = errorData['errors'];
            if (errors is Map && errors.containsKey('userError')) {
              errorMessage = (errors['userError'] as List).join(', ');
            }
          }
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception("Prijava neuspješna: ${response.statusCode} - ${response.body}");
      }
    }
  }
}

