import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

/// Service voor auto-gerelateerde API-calls.
class CarService {
  /// Haalt alle auto's op via GET /api/cars.
  static Future<List<Map<String, dynamic>>> getCars() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Niet ingelogd');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/cars'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Kon auto\'s niet ophalen');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }
}
