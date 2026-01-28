import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/maps_service.dart';

class BookingNavigationPage extends StatefulWidget {
  final double carLat;
  final double carLng;
  final String carTitle;
  final String? carPictureBase64;

  const BookingNavigationPage({
    super.key,
    required this.carLat,
    required this.carLng,
    required this.carTitle,
    required this.carPictureBase64,
  });

  @override
  State<BookingNavigationPage> createState() =>
      _BookingNavigationPageState();
}

class _BookingNavigationPageState extends State<BookingNavigationPage>
    with SingleTickerProviderStateMixin {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;
  bool _isNavigating = false;

  Uint8List? _carImageBytes;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 🔁 EXACT dezelfde image-logica als MapPage
    if (widget.carPictureBase64 != null &&
        widget.carPictureBase64!.isNotEmpty) {
      try {
        _carImageBytes = base64Decode(widget.carPictureBase64!);
      } catch (_) {
        _carImageBytes = null;
      }
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _initLocationAndNavigation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndNavigation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentLocation =
        LatLng(position.latitude, position.longitude);

    if (!mounted) return;
    setState(() {});

    await _startNavigation();
  }

  Future<void> _startNavigation() async {
    if (_currentLocation == null) return;

    setState(() {
      _isNavigating = true;
      _routePoints.clear();
    });

    final directions = await MapsService.getDirections(
      origin: _currentLocation!,
      destination: LatLng(widget.carLat, widget.carLng),
    );

    if (directions == null) return;

    if (!mounted) return;
    setState(() {
      _routePoints = directions['polyline'] as List<LatLng>;
      _routeDistance = directions['distance'] as String?;
      _routeDuration = directions['duration'] as String?;
    });

    if (_routePoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_routePoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }

  void _stopNavigation() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          'Navigate to ${widget.carTitle}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _currentLocation == null
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.automaat.app',
                retinaMode: false,
                tileBuilder: (context, tileWidget, tile) =>
                    Stack(
                      fit: StackFit.expand,
                      children: [
                        tileWidget,
                        Container(
                          color:
                          Colors.black.withOpacity(0.28),
                        ),
                      ],
                    ),
              ),

              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.blue,
                      borderStrokeWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // 🚗 AUTO MARKER — IDENTIEK AAN MapPage
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.carLat,
                      widget.carLng,
                    ),
                    width: 50,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(22.5),
                            border: Border.all(
                                color: Colors.white,
                                width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                              ),
                            ],
                            image: _carImageBytes != null
                                ? DecorationImage(
                              image: MemoryImage(
                                  _carImageBytes!),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: _carImageBytes == null
                              ? Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius:
                              BorderRadius.circular(
                                  22.5),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 👤 USER MARKER
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width:
                              60 * _pulseAnimation.value,
                              height:
                              60 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                color: Colors.blue
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ℹ️ NAVIGATIE INFO
          if (_isNavigating && _routeDistance != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3D3D)
                          .withOpacity(0.95),
                      borderRadius:
                      BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.navigation,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _routeDistance!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 16,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _routeDuration!,
                          style: const TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ⛔ STOP KNOP
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: _stopNavigation,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Stop Navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
