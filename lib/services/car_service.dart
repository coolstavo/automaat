import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'api_config.dart';

class CarService {
  // ------------------------------------------------------------
  // GET ALL CARS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getCars() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Niet ingelogd');

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

  // ------------------------------------------------------------
// GET CAR BY ID
// ------------------------------------------------------------
  static Future<Map<String, dynamic>> getCarById(int carId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/cars/$carId");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Kon auto niet ophalen: ${response.body}");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------------
  // CREATE INSPECTION (DAMAGE REPORT)
  // ------------------------------------------------------------
  Future<int> createInspection({
    required int carId,
    required int rentalId,
    required String description,
    required String result,
    required int odometer,
    String? photoBase64,
    String? photoContentType,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/inspections");

    final body = {
      "description": description,
      "result": result,
      "odometer": odometer,
      "completed": null,
      "car": {"id": carId},
      "employee": {"id": 1},
      "rental": {"id": rentalId},
      "photo": photoBase64,
      "photoContentType": photoContentType,
    };

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);
    return data["id"];
  }

  // ------------------------------------------------------------
  // UPLOAD INSPECTION PHOTO
  // ------------------------------------------------------------
  Future<void> uploadInspectionPhoto({
    required int inspectionId,
    required Uint8List photoBytes,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/inspection-photos");

    final request = http.MultipartRequest("POST", uri)
      ..headers["Authorization"] = "Bearer $token"
      ..fields["inspectionId"] = inspectionId.toString()
      ..files.add(
        http.MultipartFile.fromBytes(
          "photo",
          photoBytes,
          filename: "damage.jpg",
          contentType: http.MediaType("image", "jpeg"),
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Kon foto niet uploaden: ${response.body}");
    }
  }

  // ------------------------------------------------------------
  // CREATE RENTAL (BOOK CAR)
  // ------------------------------------------------------------
  Future<void> createRental({
    required int carId,
    required int customerId,
    required DateTime fromDate,
    required DateTime toDate,
    required double longitude,
    required double latitude,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/rentals");

    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "car": {"id": carId},
        "customer": {"id": customerId},
        "fromDate": fromDate.toIso8601String(),
        "toDate": toDate.toIso8601String(),
        "longitude": longitude,
        "latitude": latitude,
        "state": "RESERVED",
        "code": "booking_${DateTime
            .now()
            .millisecondsSinceEpoch}"
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Kon rental niet aanmaken: ${response.body}");
    }
  }

  // ------------------------------------------------------------
  // GET RENTALS FOR LOGGED-IN USER
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRentalsForCustomer(
      int customerId) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig
        .baseUrl}/api/rentals?customerId.equals=$customerId&eagerload=true");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Kon rentals niet ophalen: ${response.body}");
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }


  // ------------------------------------------------------------
  // RETURN CAR (UPDATE RENTAL STATUS)
  // ------------------------------------------------------------
  Future<void> updateRentalStatus({
    required int rentalId,
    required String newState,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig.baseUrl}/api/rentals/$rentalId");

    final response = await http.patch(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": rentalId,
        "state": newState,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Kon rental status niet updaten: ${response.body}");
    }
  }

  // ------------------------------------------------------------
  // RETURN only active CAR (UPDATE RENTAL STATUS)
  // ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getActiveRentals() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Niet ingelogd");

    final uri = Uri.parse("${ApiConfig
        .baseUrl}/api/rentals?state.in=RESERVED,ACTIVE&eagerload=true");

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Kon actieve rentals niet ophalen: ${response.body}");
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ------------------------------------------------------------
// GET inspections for a specific rental
// Returns a list of inspections (Map<String, dynamic>) for the given rentalId
// Throws exception if request fails or JSON is invalid
// ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> getInspectionsForRental(
      int rentalId) async {
    final url = Uri.parse(
        'https://jouw-backend.com/api/inspections?rentalId=$rentalId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load inspections: ${response.statusCode}');
    }
  }
}