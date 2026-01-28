import 'package:automaat/pages/search.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/logo_widget.dart';
import 'damages.dart';
import 'damage_report.dart';
import 'favorites.dart';
import 'home.dart';
import 'map.dart';
import 'rentals.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String, dynamic>> _meFuture;
  final int _currentIndex = 4;

  @override
  void initState() {
    super.initState();
    _meFuture = UserService.getMe();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _meFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Kon profiel niet laden',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final me = snapshot.data!;

          final fullName = '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'
              .trim();
          final systemUser = me['systemUser'] as Map<String, dynamic>?;
          final email = (systemUser?['email'] ?? '').toString();

          final tier = me['memberTier']?.toString() ?? 'Member';
          final spent = me['totalSpent']?.toString() ?? '\$0';
          final trips = me['tripCount']?.toString() ?? '0';

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                color: const Color(0xFF1E1E1E),
                child: Column(
                  children: [
                    const MaatAutoLogo(width: 120),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName.isEmpty ? 'User' : fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _statItem(title: 'Spent', value: spent),
                          _verticalDivider(),
                          _statItem(title: 'Member', value: tier),
                          _verticalDivider(),
                          _statItem(title: 'Trips', value: trips),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Menu-items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _profileItem(
                      icon: Icons.receipt_long,
                      title: 'My Bookings',
                      subtitle: 'View your rental history',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyBookingsPage(),
                          ),
                        );
                      },
                    ),

                    _profileItem(
                      icon: Icons.report_problem,
                      title: 'Report Damage',
                      subtitle: 'Submit a damage report with photo',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DamagesPage(
                              carId: 1,
                              rentalId: 1,
                            ),
                          ),
                        );
                      },
                    ),

                    _profileItem(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Alerts and updates',
                      onTap: () {
                        // TODO: notificatie-instellingen
                      },
                    ),
                    _profileItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update personal information',
                      onTap: () {
                        // TODO: profiel bewerken
                      },
                    ),
                    _profileItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App preferences',
                      onTap: () {
                        // TODO: app settings
                      },
                    ),
                  ],
                ),
              ),

              // Logout-knop onderaan
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: _logout,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'LOG OUT',
                      style: TextStyle(letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        ),
      ),

      // Zelfde footer als op Home, maar Profile geselecteerd
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

  Widget _statItem({required String title, required String value}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 32, color: Colors.white12);
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}
