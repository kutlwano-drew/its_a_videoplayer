import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<double> getVolume() async => (await _prefs).getDouble('volume') ?? 0.50;
  Future<void> saveVolume(double value) async => (await _prefs).setDouble('volume', value);

  Future<double> getSpeed() async => (await _prefs).getDouble('speed') ?? 1.0;
  Future<void> saveSpeed(double value) async => (await _prefs).setDouble('speed', value);

  Future<bool> getAutoPlay() async => (await _prefs).getBool('autoplay') ?? true;
  Future<void> saveAutoPlay(bool value) async => (await _prefs).setBool('autoplay', value);

  Future<int> getRepeatMode() async => (await _prefs).getInt('repeat_mode') ?? 0;
  Future<void> saveRepeatMode(int value) async => (await _prefs).setInt('repeat_mode', value);
}
