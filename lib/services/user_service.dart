import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class UserService {
  /// Haalt de ingelogde user op via `/api/AM/me`
  static Future<Map<String, dynamic>> getMe() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Niet ingelogd');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/AM/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Kon gebruiker niet ophalen');
    }

    return jsonDecode(response.body);
  }

  /// Haalt de juiste customerId op, zelfs als `/api/AM/me` geen customer bevat.
  static Future<int?> getCustomerId() async {
    final me = await getMe();
    final systemUserId = me['systemUser']?['id'];

    if (systemUserId == null) return null;

    final token = await AuthService.getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/customers?eagerload=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) return null;

    final customers = jsonDecode(response.body) as List;

    final match = customers.firstWhere(
          (c) => c['systemUser']?['id'] == systemUserId,
      orElse: () => null,
    );

    return match?['id'];
  }
  /// Haalt alle employees op
  static Future<List<Map<String, dynamic>>> getEmployees() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Niet ingelogd');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/employees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Kon employees niet ophalen');
    }

    final List data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Haalt een specifieke employee op via ID
  static Future<Map<String, dynamic>> getEmployee(int id) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Niet ingelogd');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/employees/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Kon employee niet ophalen');
    }

    return jsonDecode(response.body);
  }
}
