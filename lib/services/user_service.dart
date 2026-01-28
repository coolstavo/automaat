import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

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

  /// Initieert een wachtwoord reset door een email naar het opgegeven adres te sturen.
  static Future<void> initPasswordReset(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/account/reset-password/init'),
      headers: {
        'Content-Type': 'application/json',
        'accept': '*/*',
      },
      body: normalizedEmail,
    );

    if (response.statusCode != 200) {
      String errorMessage = 'Kon wachtwoord reset niet starten';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['detail'] != null) {
          errorMessage = errorData['detail'];
        }
      } catch (_) {
        errorMessage = 'Kon wachtwoord reset niet starten (${response.statusCode})';
      }
      throw Exception(errorMessage);
    }
  }

  /// Voltooit de wachtwoord reset met een reset-token en nieuw wachtwoord.
  static Future<void> finishPasswordReset(
    String resetToken,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/account/reset-password/finish'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'key': resetToken,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Kon wachtwoord niet resetten');
    }
  }

  /// Verandert het wachtwoord voor de ingelogde gebruiker.
  static Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Niet ingelogd');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/account/change-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Kon wachtwoord niet veranderen');
    }
  }
}
