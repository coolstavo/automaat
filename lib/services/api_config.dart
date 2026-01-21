import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Automatisch detecteren van platform en juiste URL gebruiken
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';

    } else if (Platform.isIOS) {
      // iOS simulator kan localhost gebruiken
      return 'http://localhost:8080';
      
    } else if (Platform.isAndroid) {
      // Android emulator heeft 10.0.2.2 nodig
      return 'http://10.0.2.2:8080';
    }
    // Fallback voor fysieke toestellen - vervang met je computer IP
    return 'http://localhost:8080';
  }

  static String get googleMapsApiKey {
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  }
}
