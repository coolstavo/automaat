import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/car_service.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import '../theme/logo_widget.dart';
import 'home.dart';
import 'map.dart';
import 'favorites.dart';
import 'profile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late Future<List<Map<String, dynamic>>> _carsFuture;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allCars = [];
  List<Map<String, dynamic>> _filteredCars = [];
  List<String> _recentSearches = [];

  static const _recentKeyPrefix = 'recent_searches_cars_';
  static const _maxRecent = 5;

  int _currentIndex = 2;

  // Favorites-state (per user geregeld in FavoritesService)
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _carsFuture = CarService.getCars();
    _loadRecentSearches();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _currentLogin() async {
    final me = await UserService.getMe();
    final systemUser = me['systemUser'] as Map<String, dynamic>?;
    return systemUser?['login']?.toString();
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

  Future<void> _loadRecentSearches() async {
    final login = await _currentLogin();
    if (login == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_recentKeyPrefix$login';
    final list = prefs.getStringList(key) ?? [];
    setState(() {
      _recentSearches = list;
    });
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    final login = await _currentLogin();
    if (login == null) return;

    final prefs = await SharedPreferences.getInstance();
    final key = '$_recentKeyPrefix$login';
    final list = prefs.getStringList(key) ?? [];
    list.remove(query);
    list.insert(0, query);
    if (list.length > _maxRecent) {
      list.removeRange(_maxRecent, list.length);
    }
    await prefs.setStringList(key, list);
    setState(() {
      _recentSearches = list;
    });
  }

  void _applyFilter(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => _filteredCars = _allCars);
      return;
    }

    final filtered = _allCars.where((car) {
      final brand = (car['brand'] ?? '').toString().toLowerCase();
      final model = (car['model'] ?? '').toString().toLowerCase();
      final body = (car['body'] ?? '').toString().toLowerCase();
      final fuel = (car['fuel'] ?? '').toString().toLowerCase();
      return brand.contains(query) ||
          model.contains(query) ||
          body.contains(query) ||
          fuel.contains(query);
    }).toList();

    setState(() => _filteredCars = filtered);
  }

  void _onSubmit(String query) {
    _applyFilter(query);
    _saveRecentSearch(query);
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

          if (_allCars.isEmpty) {
            _allCars = snapshot.data!;
            _filteredCars = _allCars;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Search Cars',
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

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by brand, model, or type...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _applyFilter,
                  onSubmitted: _onSubmit,
                ),
              ),
              const SizedBox(height: 8),

              // Filters-knop (placeholder)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      // TODO: echte filterdialog
                    },
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    label: const Text(
                      'Filters',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Recent searches
              if (_recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent Searches',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _recentSearches.map((q) {
                          return ChoiceChip(
                            label: Text(q),
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            selected: _searchController.text == q,
                            selectedColor: const Color(0xFF444444),
                            backgroundColor: const Color(0xFF2A2A2A),
                            onSelected: (_) {
                              _searchController.text = q;
                              _applyFilter(q);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // All cars label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'All Cars (${_filteredCars.length})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),

              // Result lijst
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: _filteredCars.length,
                  itemBuilder: (context, index) {
                    final car = _filteredCars[index];

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
                      child: Card(
                        color: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Afbeelding + hartje en rating
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child:
                                      pictureBytes != null &&
                                          pictureBytes.isNotEmpty
                                      ? Image.memory(
                                          pictureBytes,
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          height: 160,
                                          width: double.infinity,
                                          color: const Color(0xFF444444),
                                          child: const Icon(
                                            Icons.directions_car,
                                            color: Colors.white70,
                                            size: 48,
                                          ),
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          children: const [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '4.8',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _toggleFavorite(id),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: isFavorite
                                                ? Colors.red
                                                : Colors.white,
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
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
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
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    body,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        '\$$pricePerDay',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '/day',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const Spacer(),
                                      SizedBox(
                                        height: 36,
                                        child: TextButton(
                                          onPressed: () {
                                            // TODO: navigatie naar detail
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                          ),
                                          child: const Text('View'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_seat,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        nrOfSeats.isEmpty ? '-' : nrOfSeats,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.local_gas_station,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        fuel,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        modelYear,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
    ),
  );
  }
}
