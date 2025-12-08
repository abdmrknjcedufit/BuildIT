import 'dart:convert';
import 'dart:typed_data';
import 'package:buildit_mobile/providers/base_provider.dart';
import 'package:buildit_mobile/models/listing_model.dart';
import 'package:buildit_mobile/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class ListingProvider extends BaseProvider<Listing> {
  ListingProvider() : super("Listing");

  @override
  Listing fromJson(data) {
    return Listing.fromJson(data);
  }

  Future<List<String>> getRentalAvailability(int listingId) async {
    try {
      var url = "${BaseProvider.baseUrl}Listing/$listingId/rental-availability";
      var uri = Uri.parse(url);
      
      var response = await http.get(uri);
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var occupiedDates = data['occupiedDates'] as List<dynamic>;
        return occupiedDates.map((d) => d['date'] as String).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Listing>> getRecommendations(int userId, {int count = 10}) async {
    try {
      var url = "${BaseProvider.baseUrl}Listing/recommendations/$userId?count=$count";
      var uri = Uri.parse(url);
      
      var headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (AuthProvider.id != null && AuthProvider.username != null && AuthProvider.password != null) {
        var credentials = base64Encode(utf8.encode('${AuthProvider.username}:${AuthProvider.password}'));
        headers['Authorization'] = 'Basic $credentials';
      }
      
      print('🔵 Fetching recommendations from: $url');
      var response = await http.get(uri, headers: headers);
      
      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        var data = jsonDecode(response.body);
        if (data is List) {
          var listings = data.map((item) => fromJson(item)).toList();
          print('🔵 Parsed ${listings.length} recommendations');
          return listings;
        }
        print('⚠️ Response is not a List, type: ${data.runtimeType}');
        return [];
      }
      print('❌ Bad response status: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Exception in getRecommendations: $e');
      return [];
    }
  }
}

