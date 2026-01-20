import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/car_service.dart';
import '../services/favorites_service.dart';
import '../services/maps_service.dart';
import 'favorites.dart';
import 'home.dart';
import 'profile.dart';
import 'search.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _carsFuture;
  
  List<Marker> markers = [];
  List<Map<String, dynamic>> _allCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  int _currentIndex = 1;
  Set<int> _favoriteIds = {};
  bool _markersCreated = false;
  
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  List<LatLng> _routePoints = [];
  String? _routeDistance;
  String? _routeDuration;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _carsFuture = CarService.getCars();
    _loadFavorites();
    _getCurrentLocation();
    
    // Setup pulse animation
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Animate to current location with smooth transition
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            if (mounted) {
              _mapController.move(_currentLocation!, 15);
            }
          } catch (e) {
            debugPrint('Map controller error: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await FavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = ids);
  }

  Future<void> _toggleFavorite(int carId) async {
    await FavoritesService.toggleFavorite(carId);
    await _loadFavorites();
  }

  void _filterCars(String query) {
    query = query.toLowerCase().trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredCars = _allCars;
      });
    } else {
      setState(() {
        _filteredCars = _allCars.where((car) {
          final brand = (car['brand'] ?? '').toString().toLowerCase();
          final model = (car['model'] ?? '').toString().toLowerCase();
          final body = (car['body'] ?? '').toString().toLowerCase();
          final fuel = (car['fuel'] ?? '').toString().toLowerCase();
          return brand.contains(query) ||
              model.contains(query) ||
              body.contains(query) ||
              fuel.contains(query);
        }).toList();
      });
    }
    
    // Recreate markers with filtered cars
    _createMarkers(_filteredCars);
  }

  Future<void> _createMarkers(List<Map<String, dynamic>> cars) async {
    final newMarkers = <Marker>[];
    
    for (final car in cars) {
      final id = car['id'] as int;
      final lat = car['latitude'] as double?;
      final lng = car['longitude'] as double?;

      if (lat == null || lng == null) continue;

      final brand = car['brand']?.toString() ?? '';
      final model = car['model']?.toString() ?? '';
      final title = '$brand $model'.trim();
      final pricePerDay = (car['price'] ?? car['pricePerDay'] ?? 0).toString();

      final pictureBase64 = car['picture'] as String?;
      Uint8List? pictureBytes;
      if (pictureBase64 != null && pictureBase64.isNotEmpty) {
        try {
          pictureBytes = base64Decode(pictureBase64);
        } catch (_) {
          pictureBytes = null;
        }
      }

      final isFavorite = _favoriteIds.contains(id);

      final marker = Marker(
        point: LatLng(lat, lng),
        width: 50,
        height: 60,
        child: GestureDetector(
          onTap: () {
            _showCarBottomSheet(
              context: context,
              id: id,
              title: title,
              pricePerDay: pricePerDay,
              body: car['body']?.toString() ?? '',
              fuel: car['fuel']?.toString() ?? '',
              seats: (car['nrOfSeats'] ?? car['numberOfSeats'] ?? '').toString(),
              modelYear: (car['modelYear'] ?? car['year'] ?? '').toString(),
              imageBytes: pictureBytes,
              isFavorite: isFavorite,
              carLat: lat,
              carLng: lng,
              onFavoriteTap: () => _toggleFavorite(id),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  '\$$pricePerDay',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22.5),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                    ),
                  ],
                  image: pictureBytes != null && pictureBytes.isNotEmpty
                      ? DecorationImage(
                          image: MemoryImage(pictureBytes),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pictureBytes == null || pictureBytes.isEmpty
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(22.5),
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
      );
      newMarkers.add(marker);
    }

    if (mounted) {
      setState(() {
        markers = newMarkers;
        _markersCreated = true;
      });
    }
  }

  Future<void> _startNavigation({
    required double carLat,
    required double carLng,
    required String carTitle,
  }) async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    setState(() {
      _isNavigating = true;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });

    final directions = await MapsService.getDirections(
      origin: _currentLocation!,
      destination: LatLng(carLat, carLng),
    );

    if (directions == null) {
      if (mounted) {
        setState(() => _isNavigating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not calculate route')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _routePoints = directions['polyline'] as List<LatLng>;
        _routeDistance = directions['distance'] as String?;
        _routeDuration = directions['duration'] as String?;
      });

      // Zoom to fit the route
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
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _routePoints = [];
      _routeDistance = null;
      _routeDuration = null;
    });
  }

  void _showCarBottomSheet({
    required BuildContext context,
    required int id,
    required String title,
    required String pricePerDay,
    required String body,
    required String fuel,
    required String seats,
    required String modelYear,
    required Uint8List? imageBytes,
    required bool isFavorite,
    required double carLat,
    required double carLng,
    required VoidCallback onFavoriteTap,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onFavoriteTap,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$ $pricePerDay',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'per day',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '$seats seats • $fuel',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startNavigation(
                      carLat: carLat,
                      carLng: carLng,
                      carTitle: title,
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Start Navigation'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _carsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Kon auto\'s niet laden',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (_allCars.isEmpty) {
            _allCars = snapshot.data!;
            _filteredCars = _allCars;
          }

          if (!_markersCreated) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _createMarkers(_filteredCars);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(53.2107, 6.5679),
                  initialZoom: 12,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.automaat.app',
                  ),
                  // Route polyline
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 5.0,
                          color: Colors.blue,
                          borderStrokeWidth: 2.0,
                          borderColor: Colors.white,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                  // Current location marker
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 80,
                          height: 80,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 60 * _pulseAnimation.value,
                                    height: 60 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
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
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
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
              
              // Search bar and car count - only show when NOT navigating
              if (!_isNavigating)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D3D3D).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                    cursorColor: Colors.white,
                                    decoration: const InputDecoration(
                                      hintText: 'Search by brand, model, or type...',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                    ),
                                    onChanged: _filterCars,
                                  ),
                                ),
                                if (_searchController.text.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _searchController.clear();
                                      _filterCars('');
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white54,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${_filteredCars.length} cars available nearby',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Navigation info card - slimmer and rounder
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
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D3D3D).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _routeDistance ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
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
                              _routeDuration ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              
              // My Location button
              Positioned(
                bottom: 100,
                right: 16,
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () async {
                      await _getCurrentLocation();
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D3D).withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: _currentLocation != null ? Colors.white : Colors.white54,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Stop Navigation button - at the bottom
              if (_isNavigating)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: TextButton(
                          onPressed: _stopNavigation,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Stop Navigation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == _currentIndex) return;
          Widget page;
          switch (index) {
            case 0:
              page = const HomePage();
              break;
            case 1:
              page = const MapPage();
              break;
            case 2:
              page = const SearchPage();
              break;
            case 3:
              page = const FavoritesPage();
              break;
            case 4:
            default:
              page = const ProfilePage();
          }
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
