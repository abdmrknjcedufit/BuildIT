import 'dart:convert';
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/providers/auth_provider.dart';
import 'package:http/http.dart' as http;

class PaymentProvider extends BaseProvider<Map<String, dynamic>> {
  PaymentProvider() : super("Payment");

  @override
  Map<String, dynamic> fromJson(data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {'data': data};
  }

  Future<Map<String, dynamic>> createCheckoutSession({
    required double amount,
    required int userId,
    required List<int> cartIds,
    int? deliveryProviderId,
    String? deliveryType,
    String? shippingAddress,
    String? description,
    String? successUrl,
    String? cancelUrl,
  }) async {
    var url = "${BaseProvider.baseUrl}Payment/create-checkout-session";
    var uri = Uri.parse(url);
    var headers = {"Content-Type": "application/json"};

    var requestBody = {
      'amount': amount,
      'description': description ?? 'Narudžba BuildIT',
      'userId': userId,
      'cartIds': cartIds,
      'deliveryProviderId': deliveryProviderId,
      'deliveryType': deliveryType,
      'shippingAddress': shippingAddress,
      'successUrl': successUrl ?? 'buildit://payment-success',
      'cancelUrl': cancelUrl ?? 'buildit://payment-cancel',
    };

    print('🔵 FLUTTER-PROVIDER: createCheckoutSession - URL: $url');
    print('🔵 FLUTTER-PROVIDER: Request body: $requestBody');

    var jsonRequest = jsonEncode(requestBody);
    var response = await http.post(uri, headers: headers, body: jsonRequest);

    print('🔵 FLUTTER-PROVIDER: Response status: ${response.statusCode}');
    print('🔵 FLUTTER-PROVIDER: Response body: ${response.body}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      var data = jsonDecode(response.body);
      print('✅ FLUTTER-PROVIDER: Checkout sesija kreirana uspješno');
      return data as Map<String, dynamic>;
    } else {
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
          errorMessage = response.body;
        }
      }
      print('❌ FLUTTER-PROVIDER: Greška pri kreiranju checkout sesije: $errorMessage');
      throw Exception(errorMessage ?? 'Greška pri kreiranju checkout sesije');
    }
  }

  Future<Map<String, dynamic>> verifyPayment(String sessionId) async {
    var url = "${BaseProvider.baseUrl}Payment/verify-payment";
    var uri = Uri.parse(url);
    var headers = {"Content-Type": "application/json"};

    var requestBody = {
      'sessionId': sessionId,
    };

    print('🔵 FLUTTER-PROVIDER: verifyPayment - URL: $url, sessionId: $sessionId');

    try {
      var jsonRequest = jsonEncode(requestBody);
      var response = await http.post(uri, headers: headers, body: jsonRequest);

      print('🔵 FLUTTER-PROVIDER: verifyPayment response status: ${response.statusCode}');
      print('🔵 FLUTTER-PROVIDER: verifyPayment response body: ${response.body}');

      if (response.body.isNotEmpty) {
        try {
          var data = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            print('✅ FLUTTER-PROVIDER: verifyPayment uspješan - data: $data');
            return data;
          } else {
            print('⚠️ FLUTTER-PROVIDER: verifyPayment nije uspješan - status: ${response.statusCode}, data: $data');
            return data;
          }
        } catch (e) {
          print('❌ FLUTTER-PROVIDER: Greška pri parsiranju response body: $e');
          return {'success': false, 'message': 'Greška pri parsiranju odgovora'};
        }
      } else {
        print('⚠️ FLUTTER-PROVIDER: verifyPayment - prazan response body');
        return {'success': false, 'message': 'Prazan odgovor od servera'};
      }
    } catch (e) {
      print('❌ FLUTTER-PROVIDER: Network greška pri verifyPayment: $e');
      return {'success': false, 'message': 'Greška pri komunikaciji sa serverom: $e'};
    }
  }
}

