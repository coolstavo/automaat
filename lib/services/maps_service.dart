import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'api_config.dart';

class MapsService {
  // Option 1: Google Maps (requires valid API key)
  static Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Try Google Maps first
    try {
      return await _getGoogleDirections(origin, destination);
    } catch (e) {
      print('Google Maps failed: $e');
      print('Falling back to OpenStreetMap routing...');
      return await _getOSRMDirections(origin, destination);
    }
  }

  static Future<Map<String, dynamic>?> _getGoogleDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&mode=walking'
      '&key=${ApiConfig.googleMapsApiKey}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (data['status'] != 'OK') {
      throw Exception('API: ${data['status']} - ${data['error_message']}');
    }

    final routes = data['routes'] as List;
    if (routes.isEmpty) return null;

    final route = routes[0] as Map<String, dynamic>;
    final polylinePoints = _decodePolyline(
      route['overview_polyline']['points'] as String,
    );

    final leg = (route['legs'] as List)[0] as Map<String, dynamic>;
    
    return {
      'polyline': polylinePoints,
      'distance': leg['distance']['text'],
      'duration': leg['duration']['text'],
      'distanceValue': leg['distance']['value'],
      'durationValue': leg['duration']['value'],
    };
  }

  // Option 2: Free OSRM fallback (no API key needed)
  static Future<Map<String, dynamic>?> _getOSRMDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=polyline',
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (data['code'] != 'Ok') {
        return null;
      }

      final routes = data['routes'] as List;
      if (routes.isEmpty) return null;

      final route = routes[0] as Map<String, dynamic>;
      final polylinePoints = _decodePolyline(route['geometry'] as String);
      
      final distance = route['distance'] as num;
      final duration = route['duration'] as num;

      return {
        'polyline': polylinePoints,
        'distance': '${(distance / 1000).toStringAsFixed(1)} km',
        'duration': '${(duration / 60).round()} min',
        'distanceValue': distance.toInt(),
        'durationValue': duration.toInt(),
      };
    } catch (e) {
      print('OSRM error: $e');
      return null;
    }
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
