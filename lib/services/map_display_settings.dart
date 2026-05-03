import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted preferences that affect the detection field grid in Data Logs.
class MapDisplaySettings {
  MapDisplaySettings._();

  static const _keyShowNeutralized = 'show_neutralized_on_map';

  static final ValueNotifier<bool> showNeutralizedOnMap =
      ValueNotifier<bool>(true);

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    showNeutralizedOnMap.value = p.getBool(_keyShowNeutralized) ?? true;
  }

  static Future<void> setShowNeutralizedOnMap(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyShowNeutralized, value);
    showNeutralizedOnMap.value = value;
  }
}
