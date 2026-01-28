import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/car_service.dart';
import '../services/favorites_service.dart';
import '../theme/logo_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import 'car_details.dart';

/// Haalt data uit /api/cars.
/// 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _currentIndex = 0;

  late Future<List<Map<String, dynamic>>> _carsFuture;
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _carsFuture = _getAvailableCars();
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

  /// 🔥 FILTER: haal alleen auto's op die NIET actief geboekt zijn
  Future<List<Map<String, dynamic>>> _getAvailableCars() async {
    final allCars = await CarService.getCars();
    final activeRentals = await CarService().getActiveRentals();

    final now = DateTime.now();

    final availableCars = allCars.where((car) {
      final carId = car['id'];

      final overlappingRental = activeRentals.any((rental) {
        final rentalCarId = rental['car']?['id'];
        final from = DateTime.tryParse(rental['fromDate'] ?? '');
        final to = DateTime.tryParse(rental['toDate'] ?? '');

        if (from == null || to == null) return false;

        // Check of de huidige datum binnen de boekingsperiode valt
        final overlaps = now.isBefore(to) && now.isAfter(from);

        return rentalCarId == carId && overlaps;
      });

      return !overlappingRental;
    }).toList();

    return availableCars;
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
                  'Geen beschikbare auto\'s',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

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
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: cars.length,
                    itemBuilder: (context, index) {
                      final car = cars[index];

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
                      final modelYear = (car['modelYear'] ?? car['year'] ?? '')
                          .toString();
                      final transmission = car['transmission']?.toString();
                      final location = car['location']?.toString();

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
              ],
            );
          },
        ),
      ),
      // Footer
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
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
                          style: TextStyle(color: Colors.white70, fontSize: 12),
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

