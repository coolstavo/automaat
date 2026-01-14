import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

/// Service voor user‑/customer‑gerelateerde API‑calls.
class UserService {
  /// Haalt de huidige ingelogde CUSTOMER op via `/api/AM/me`.
  static Future<Map<String, dynamic>> getMe() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Niet ingelogd');
    }

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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
