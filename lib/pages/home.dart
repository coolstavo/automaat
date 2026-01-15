import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/car_service.dart';
import '../services/favorites_service.dart';
import '../theme/logo_widget.dart';
import 'car_details.dart';
import 'favorites.dart';
import 'profile.dart';
import 'search.dart';

/// Haalt data uit /api/cars.

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// Per pagina max 10 auto's weergeven.
class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  int _currentPage = 0;
  static const int _pageSize = 10;

  late Future<List<Map<String, dynamic>>> _carsFuture;
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _carsFuture = CarService.getCars();
    _loadFavorites();
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

  int _totalPagesFor(List cars) =>
      (cars.length / _pageSize).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> _carsForPage(List<Map<String, dynamic>> cars) {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, cars.length);
    return cars.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
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

            final cars = snapshot.data!;
            if (cars.isEmpty) {
              return const Center(
                child: Text(
                  'Geen auto\'s gevonden',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final totalPages = _totalPagesFor(cars);
            if (_currentPage >= totalPages) {
              _currentPage = totalPages - 1;
            }
            final pageCars = _carsForPage(cars);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Text(
                          'Find your\nperfect ride',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const MaatAutoLogo(width: 80),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: pageCars.length,
                    itemBuilder: (context, index) {
                      final car = pageCars[index];

                      final id = car['id'] as int;
                      final brand = car['brand']?.toString() ?? '';
                      final model = car['model']?.toString() ?? '';
                      final title = '$brand $model'.trim();

                      final pricePerDay =
                      (car['price'] ?? car['pricePerDay'] ?? 0).toString();

                      final fuel = car['fuel']?.toString() ?? '';
                      final body = car['body']?.toString() ?? '';
                      final nrOfSeats =
                      (car['nrOfSeats'] ?? car['numberOfSeats'] ?? '')
                          .toString();
                      final modelYear =
                      (car['modelYear'] ?? car['year'] ?? '').toString();
                      final transmission =
                      car['transmission']?.toString(); // optioneel
                      final location = car['location']?.toString(); // optioneel

                      final pictureBase64 = car['picture'] as String?;
                      Uint8List? pictureBytes;
                      if (pictureBase64 != null &&
                          pictureBase64.isNotEmpty) {
                        try {
                          pictureBytes = base64Decode(pictureBase64);
                        } catch (_) {
                          pictureBytes = null;
                        }
                      }

                      final isFavorite = _favoriteIds.contains(id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: CarCard(
                          title: title.isEmpty ? 'Car' : title,
                          pricePerDay: pricePerDay,
                          body: body,
                          fuel: fuel,
                          seats: nrOfSeats.isEmpty ? null : nrOfSeats,
                          modelYear: modelYear.isEmpty ? null : modelYear,
                          imageBytes: pictureBytes,
                          isFavorite: isFavorite,
                          onFavoriteTap: () => _toggleFavorite(id),
                          onBookNow: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarDetailsPage(
                                  id: id,
                                  title: title.isEmpty ? 'Car' : title,
                                  body: body,
                                  fuel: fuel,
                                  pricePerDay: pricePerDay,
                                  seats: nrOfSeats.isEmpty ? null : nrOfSeats,
                                  modelYear:
                                  modelYear.isEmpty ? null : modelYear,
                                  transmission: transmission,
                                  location: location,
                                  imageBytes: pictureBytes,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _currentPage == 0
                            ? null
                            : () {
                          setState(() {
                            _currentPage--;
                          });
                        },
                        child: const Text('Previous'),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Page ${_currentPage + 1} / $totalPages',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _currentPage >= totalPages - 1
                            ? null
                            : () {
                          setState(() {
                            _currentPage++;
                          });
                        },
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      // Footer
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
              page = const SearchPage();
              break;
            case 2:
              page = const FavoritesPage();
              break;
            case 3:
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

/// Kaart voor één auto.
/// 'Dom' gehouden zodat hij op andere schermen hergebruikt kan worden.
class CarCard extends StatelessWidget {
  final String title;
  final String pricePerDay;
  final String body;
  final String fuel;
  final String? seats;
  final String? modelYear;
  final Uint8List? imageBytes;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onBookNow;

  const CarCard({
    super.key,
    required this.title,
    required this.pricePerDay,
    required this.body,
    required this.fuel,
    this.seats,
    this.modelYear,
    this.imageBytes,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      imageWidget = Image.memory(
        imageBytes!,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(
        height: 160,
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF444444),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: const Icon(
          Icons.directions_car,
          color: Colors.white70,
          size: 48,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageWidget,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$$pricePerDay',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'per day',
                          style:
                          TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _iconSpec(
                      icon: Icons.event_seat,
                      main: seats ?? '-',
                      sub: 'Seats',
                    ),
                    _iconSpec(
                      icon: Icons.directions_car,
                      main: body,
                      sub: 'Body',
                    ),
                    _iconSpec(
                      icon: Icons.local_gas_station,
                      main: fuel,
                      sub: 'Fuel',
                    ),
                    _iconSpec(
                      icon: Icons.calendar_today_outlined,
                      main: modelYear ?? '-',
                      sub: 'Year',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: onBookNow,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(letterSpacing: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _iconSpec({
  required IconData icon,
  required String main,
  required String sub,
}) {
  return Column(
    children: [
      Icon(icon, color: Colors.white, size: 16),
      const SizedBox(height: 4),
      Text(main, style: const TextStyle(color: Colors.white, fontSize: 11)),
      Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 10)),
    ],
  );
}
