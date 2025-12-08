import 'dart:convert';
import 'package:buildit_mobile/models/search_result.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

abstract class BaseProvider<T> with ChangeNotifier {
  static String? _baseUrl;
  String _endpoint = "";

  BaseProvider(String endpoint) {
    _endpoint = endpoint;
    _baseUrl = const String.fromEnvironment(
      "baseUrl",
      defaultValue: "http://10.0.2.2:5031/",
    );
  }
  
  static String get baseUrl {
    if (_baseUrl == null) {
      throw Exception("Base URL nije postavljen");
    }
    return _baseUrl!;
  }

  Future<SearchResult<T>> get({
    dynamic filter,
    int? page,
    int? pageSize,
  }) async {
    var url = "${baseUrl}$_endpoint";

    Map<String, dynamic> queryParams = {};

    if (filter != null) {
      queryParams.addAll(Map<String, dynamic>.from(filter));
    }

    if (page != null) {
      queryParams['page'] = page;
    }
    if (pageSize != null) {
      queryParams['pageSize'] = pageSize;
    }
    if (queryParams.isNotEmpty) {
      var queryString = getQueryString(queryParams);
      url = "$url?$queryString";
    }
    var uri = Uri.parse(url);
    var headers = createHeaders();

    print("🔵 GET Request: $url");
    print("🔵 Query params: $queryParams");

    var response = await http.get(uri, headers: headers);
    
    print("🔵 Response status: ${response.statusCode}");

    print("🔵 Response body: ${response.body}");

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      var result = SearchResult<T>();

      result.count = data['count'];

      for (var item in data['resultList']) {
        result.result.add(fromJson(item));
      }

      return result;
    } else {
      throw Exception("Nepoznata greška");
    }
  }

  Future<T> getById(int id) async {
    var url = "${baseUrl}$_endpoint/$id";

    var uri = Uri.parse(url);
    var headers = createHeaders();

    var response = await http.get(uri, headers: headers);
    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);

      return fromJson(data);
    } else {
      throw Exception("Nepoznata greška");
    }
  }

  Future<T> insert(dynamic request, {bool requireAuth = true, String? customEndpoint}) async {
    var endpoint = customEndpoint != null ? "$_endpoint/$customEndpoint" : _endpoint;
    var url = "${baseUrl}$endpoint";
    var uri = Uri.parse(url);
    var headers = requireAuth 
        ? createHeaders() 
        : {"Content-Type": "application/json"};

    var jsonRequest = jsonEncode(request);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Nepoznata greška");
    }
  }

  Future<void> delete(int id) async {
    var url = "${baseUrl}$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();
    
    print("🔵 DELETE Request: $url");
    
    var response = await http.delete(uri, headers: headers);
    
    print("🔵 DELETE Response status: ${response.statusCode}");
    print("🔵 DELETE Response body: ${response.body}");
    
    if (response.statusCode == 204 || response.statusCode == 200) {
      return;
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    
    if (response.statusCode >= 400) {
      String? errorMessage;
      
      if (response.body.isNotEmpty) {
        try {
          final dynamic errorResponse = jsonDecode(response.body);
          if (errorResponse is Map<String, dynamic>) {
            if (errorResponse.containsKey('message')) {
              errorMessage = errorResponse['message'];
            }
          }
        } catch (e) {
          print("⚠️ Error parsing response body: $e");
        }
      }
      
      throw UserFriendlyException(errorMessage ?? "Greška pri brisanju: ${response.statusCode}");
    }
    
    throw UserFriendlyException("Nepoznata greška");
  }

  Future<T> update(int id, [dynamic request]) async {
    var url = "${baseUrl}$_endpoint/$id";
    var uri = Uri.parse(url);
    var headers = createHeaders();

    var jsonRequest = jsonEncode(request);
    var response = await http.put(uri, headers: headers, body: jsonRequest);

    if (isValidResponse(response)) {
      var data = jsonDecode(response.body);
      return fromJson(data);
    } else {
      throw Exception("Nepoznata greška");
    }
  }

  T fromJson(data) {
    throw Exception("Metoda nije implementirana");
  }

  bool isValidResponse(Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      if (response.body.isEmpty) {
        return false;
      }

      final dynamic errorResponse = jsonDecode(response.body);
      String? errorMessage;

      if (errorResponse is Map<String, dynamic>) {
        if (errorResponse.containsKey('message')) {
          errorMessage = errorResponse['message'];
        } else if (errorResponse['errors'] is Map<String, dynamic> &&
            errorResponse['errors']['userError'] is List) {
          errorMessage = (errorResponse['errors']['userError'] as List).join(
            ', ',
          );
        }
      }

      if (response.statusCode == 400) {
        throw UserFriendlyException(errorMessage ?? "Neispravan zahtjev");
      } else if (response.statusCode == 401) {
        throw UserFriendlyException(errorMessage ?? "Neautorizovan pristup");
      } else if (response.statusCode == 403) {
        throw UserFriendlyException(errorMessage ?? "Pristup odbijen");
      } else if (response.statusCode == 404) {
        throw UserFriendlyException(errorMessage ?? "Nije pronađeno");
      } else if (response.statusCode >= 500) {
        throw UserFriendlyException(errorMessage ?? "Greška na serveru");
      }

      throw UserFriendlyException(errorMessage ?? "Neočekivana greška");
    } catch (e) {
      if (e is UserFriendlyException) {
        rethrow;
      }
      throw UserFriendlyException(
        "Neuspješna obrada odgovora. Provjerite konekciju i pokušajte ponovo.",
      );
    }
  }

  Map<String, String> createHeaders() {
    String username = AuthProvider.username ?? "";
    String password = AuthProvider.password ?? "";

    String basicAuth =
        "Basic ${base64Encode(utf8.encode('$username:$password'))}";

    return {
      "Content-Type": "application/json",
      "Authorization": basicAuth,
      "X-Client-Type": "mobile",
    };
  }

  String getQueryString(
    Map params, {
    String prefix = '&',
    bool inRecursion = false,
  }) {
    String query = '';
    params.forEach((key, value) {
      if (inRecursion) {
        if (key is int) {
          key = '[$key]';
        } else if (value is List || value is Map) {
          key = '.$key';
        } else {
          key = '.$key';
        }
      }
      if (value is String || value is int || value is double || value is bool) {
        var encoded = value;
        if (value is String) {
          encoded = Uri.encodeComponent(value);
        } else if (value is bool) {
          encoded = value.toString().toLowerCase();
        }
        query += '$prefix$key=$encoded';
      } else if (value is DateTime) {
        query += '$prefix$key=${value.toIso8601String()}';
      } else if (value is List || value is Map) {
        if (value is List) value = value.asMap();
        value.forEach((k, v) {
          query += getQueryString(
            {k: v},
            prefix: '$prefix$key',
            inRecursion: true,
          );
        });
      }
    });
    return query;
  }
}

class UserFriendlyException implements Exception {
  final String message;

  UserFriendlyException(this.message);

  @override
  String toString() => message;
}

