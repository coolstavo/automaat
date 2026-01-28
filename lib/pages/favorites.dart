import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/favorites_service.dart';
import '../theme/logo_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home.dart' show CarCard;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final int _currentIndex = 3; // voor bottom navigation
  late Future<List<Map<String, dynamic>>> _carsFuture;
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _carsFuture = CarService.getCars(); // alle auto's ophalen
    _loadFavorites(); // favorieten ophalen
  }

  // Favorieten ids ophalen uit lokale storage/service
  Future<void> _loadFavorites() async {
    final ids = await FavoritesService.getFavoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = ids);
  }

  // Toggle favorite status
  Future<void> _toggleFavorite(int carId) async {
    await FavoritesService.toggleFavorite(carId);
    await _loadFavorites();
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
                  'Kon favorieten niet laden',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            final cars = snapshot.data!;
            final favoriteCars = cars.where((car) {
              final id = car['id'] as int;
              return _favoriteIds.contains(id);
            }).toList();

            if (favoriteCars.isEmpty) {
              return const Center(
                child: Text(
                  'Nog geen favoriete auto\'s',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Column(
              children: [
                // Header met titel en logo
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'My Favorites',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      MaatAutoLogo(width: 80),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${favoriteCars.length} cars saved',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lijst met favoriete auto's
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: favoriteCars.length,
                    itemBuilder: (context, index) {
                      final car = favoriteCars[index];
                      final id = car['id'] as int;

                      final brand = car['brand']?.toString() ?? '';
                      final model = car['model']?.toString() ?? '';
                      final title = '$brand $model'.trim();

                      final pricePerDay =
                      (car['price'] ?? car['pricePerDay'] ?? 0).toString();

                      final fuel = car['fuel']?.toString() ?? '';
                      final body = car['body']?.toString() ?? '';
                      final nrOfSeats =
                      (car['nrOfSeats'] ?? car['numberOfSeats'] ?? '').toString();
                      final modelYear = (car['modelYear'] ?? car['year'] ?? '').toString();
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
                          isFavorite: true,
                          onFavoriteTap: () => _toggleFavorite(id),
                          // Book Now knop met navigatie naar details
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
                                  modelYear: modelYear.isEmpty ? null : modelYear,
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
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
    );
  }
}
