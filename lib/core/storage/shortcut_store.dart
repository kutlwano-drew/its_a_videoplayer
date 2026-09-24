import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ShortcutStore {
  static const _key = 'shortcuts';

  Future<Map<String, String>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return Map<String, String>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(values));
  }
}
