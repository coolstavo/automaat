import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Verantwoordelijk voor inloggen, registreren en JWT‑opslag.
class AuthService {
  static const _tokenKey = 'auth_token';

  /// Logt de gebruiker in via `/api/authenticate` en bewaart de JWT.
  ///
  /// Gooit een [Exception] als inloggen niet lukt of als er geen token is.
  static Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/authenticate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode != 200) {
      // Generieke melding, geen informatielek over accounts.
      throw Exception('Ongeldige gebruikersnaam of wachtwoord');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['id_token'] as String?;

    if (token == null) {
      throw Exception('Token niet gevonden in response');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Registreert een nieuwe gebruiker via `/api/AM/register`.
  ///
  /// Dit endpoint maakt zowel een USER als een CUSTOMER aan.
  static Future<void> register({
    required String login,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/AM/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'login': login,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'langKey': 'en',
        'password': password,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Registratie mislukt');
    }
  }

  /// Leest het huidige JWT token uit local storage.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Verwijdert het JWT token, effectief uitloggen.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
