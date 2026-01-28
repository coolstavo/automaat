import 'package:automaat/pages/change_password.dart';
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
                  ],
                ),
              ),


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
                      icon: Icons.lock_outline,
                      title: 'Reset Password',
                      subtitle: 'Change your account password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
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
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex),
  );
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
