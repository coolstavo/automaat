import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_service.dart';

class FavoritesService {
  static const _keyPrefix = 'favorite_car_ids_';

  // Haal huidige login op (of userId als je die hebt).
  static Future<String?> _currentLogin() async {
    final me = await UserService.getMe();        // { ..., systemUser: { login: ... } }
    final systemUser = me['systemUser'] as Map<String, dynamic>?;
    return systemUser?['login']?.toString();
  }

  static Future<Set<int>> getFavoriteIds() async {
    final login = await _currentLogin();
    if (login == null) return <int>{};

    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$login';
    final json = prefs.getString(key);
    if (json == null) return <int>{};
    final list = (jsonDecode(json) as List).cast<int>();
    return list.toSet();
  }

  static Future<void> _saveFavoriteIds(String login, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$login';
    await prefs.setString(key, jsonEncode(ids.toList()));
  }

  static Future<void> toggleFavorite(int carId) async {
    final login = await _currentLogin();
    if (login == null) return;

    final ids = await getFavoriteIds();
    if (ids.contains(carId)) {
      ids.remove(carId);
    } else {
      ids.add(carId);
    }
    await _saveFavoriteIds(login, ids);
  }
}
