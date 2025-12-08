import 'dart:convert';
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/models/listing_model.dart';
import 'package:buildit_desktop/providers/auth_provider.dart';
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
}

