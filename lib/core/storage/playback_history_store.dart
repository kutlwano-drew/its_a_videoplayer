import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PlaybackHistoryStore {
  static const _key = 'playback_history';

  Future<Map<String, double>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<double?> readPosition(String path) async => (await read())[path];

  Future<void> clearPosition(String path) async {
    final history = await read();
    history.remove(path);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history));
  }

  Future<void> writePosition(String path, double seconds) async {
    final history = await read();
    history[path] = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(history));
  }
}
