import 'package:flutter/material.dart';
import '../pages/home.dart';
import '../pages/map.dart';
import '../pages/search.dart';
import '../pages/favorites.dart';
import '../pages/profile.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

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
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTabTapped(context, index),
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      enableFeedback: false,
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
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
