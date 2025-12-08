import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:buildit_desktop/models/dashboard_stats_model.dart';
import 'package:buildit_desktop/models/statistics_data_model.dart';
import 'package:buildit_desktop/providers/base_provider.dart';
import 'package:buildit_desktop/providers/auth_provider.dart';

class DashboardProvider extends BaseProvider<DashboardStats> {
  DashboardProvider() : super("Dashboard");

  @override
  DashboardStats fromJson(data) {
    return DashboardStats.fromJson(data);
  }

  Future<DashboardStats> getStats() async {
    var url = "${BaseProvider.baseUrl}Dashboard/stats";
    var uri = Uri.parse(url);
    
    Map<String, String> headers = {};
    if (AuthProvider.username != null && AuthProvider.password != null) {
      var credentials = base64Encode(
        utf8.encode('${AuthProvider.username}:${AuthProvider.password}'),
      );
      headers['Authorization'] = 'Basic $credentials';
    }
    
    var response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return DashboardStats.fromJson(data);
    } else {
      throw Exception('Failed to load dashboard stats: ${response.statusCode}');
    }
  }

  Future<StatisticsData> getStatistics() async {
    var url = "${BaseProvider.baseUrl}Dashboard/statistics";
    var uri = Uri.parse(url);
    
    Map<String, String> headers = {};
    if (AuthProvider.username != null && AuthProvider.password != null) {
      var credentials = base64Encode(
        utf8.encode('${AuthProvider.username}:${AuthProvider.password}'),
      );
      headers['Authorization'] = 'Basic $credentials';
    }
    
    var response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return StatisticsData.fromJson(data);
    } else {
      throw Exception('Failed to load statistics: ${response.statusCode}');
    }
  }
}

