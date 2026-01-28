import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:automaat/services/auth_service.dart';

class MockClient extends Mock implements http.Client {}

void main() {
  group('AuthService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({}); // reset elke test
    });

    test('getToken en logout werken', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'abc');

      final token = await AuthService.getToken();
      expect(token, 'abc');

      await AuthService.logout();
      final tokenAfterLogout = await AuthService.getToken();
      expect(tokenAfterLogout, isNull);
    });
  });
}
