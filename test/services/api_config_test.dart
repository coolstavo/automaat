import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:automaat/services/api_config.dart'; // pas aan naar jouw pad
import 'dart:io';

void main() {
  group('ApiConfig', () {
    test('baseUrl returns correct value for web', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia; // Fuchsia simuleert web
      kIsWeb == true;

      final url = ApiConfig.baseUrl;
      expect(url, 'http://localhost:8080');
    });

    test('googleMapsApiKey returns string (can be empty)', () {
      final key = ApiConfig.googleMapsApiKey;
      expect(key, isA<String>());
    });

    test('baseUrl returns Android emulator URL', () {
      if (!kIsWeb && Platform.isAndroid) {
        final url = ApiConfig.baseUrl;
        expect(url, 'http://10.0.2.2:8080');
      }
    });

    test('baseUrl returns iOS simulator URL', () {
      if (!kIsWeb && Platform.isIOS) {
        final url = ApiConfig.baseUrl;
        expect(url, 'http://localhost:8080');
      }
    });

    test('baseUrl returns fallback for other platforms', () {
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        final url = ApiConfig.baseUrl;
        expect(url, 'http://localhost:8080');
      }
    });
  });
}
