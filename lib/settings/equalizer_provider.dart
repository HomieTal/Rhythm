import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerProvider extends ChangeNotifier {
  // Default 10-band equalizer gains (in dB)
  List<double> gains = List.filled(10, 0.0);
  double volume = 1.0;
  double preamp = 0.0; // in dB
  double speed = 1.0;
  double pitch = 1.0;
  bool isEnabled = false;

  // Preset names
  static const List<String> presets = [
    'Flat',
    'Rock',
    'Pop',
    'Jazz',
    'Classical',
    'Bass Boost',
    'Treble Boost',
    'Vocal',
    'Electronic',
    'Custom',
  ];

  String currentPreset = 'Flat';

  EqualizerProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load gains
      final savedGains = prefs.getStringList('eq_gains');
      if (savedGains != null && savedGains.length == 10) {
        gains = savedGains.map((e) => double.tryParse(e) ?? 0.0).toList();
      }

      volume = prefs.getDouble('eq_volume') ?? 1.0;
      preamp = prefs.getDouble('eq_preamp') ?? 0.0;
      speed = prefs.getDouble('eq_speed') ?? 1.0;
      pitch = prefs.getDouble('eq_pitch') ?? 1.0;
      isEnabled = prefs.getBool('eq_enabled') ?? false;
      currentPreset = prefs.getString('eq_preset') ?? 'Flat';

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading equalizer settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('eq_gains', gains.map((e) => e.toString()).toList());
      await prefs.setDouble('eq_volume', volume);
      await prefs.setDouble('eq_preamp', preamp);
      await prefs.setDouble('eq_speed', speed);
      await prefs.setDouble('eq_pitch', pitch);
      await prefs.setBool('eq_enabled', isEnabled);
      await prefs.setString('eq_preset', currentPreset);
    } catch (e) {
      debugPrint('Error saving equalizer settings: $e');
    }
  }

  void setGain(int band, double value) {
    if (band >= 0 && band < gains.length) {
      gains[band] = value.clamp(-12.0, 12.0);
      currentPreset = 'Custom';
      notifyListeners();
      _saveSettings();
    }
  }

  void setGains(List<double> newGains) {
    if (newGains.length == gains.length) {
      gains = newGains.map((e) => e.clamp(-12.0, 12.0)).toList();
      notifyListeners();
      _saveSettings();
    }
  }

  void setVolume(double value) {
    volume = value.clamp(0.0, 1.0);
    notifyListeners();
    _saveSettings();
  }

  void setPreamp(double value) {
    preamp = value.clamp(-12.0, 12.0);
    notifyListeners();
    _saveSettings();
  }

  void setSpeed(double value) {
    speed = value.clamp(0.5, 2.0);
    notifyListeners();
    _saveSettings();
  }

  void setPitch(double value) {
    pitch = value.clamp(0.5, 2.0);
    notifyListeners();
    _saveSettings();
  }

  void toggleEnabled(bool value) {
    isEnabled = value;
    notifyListeners();
    _saveSettings();
  }

  void applyPreset(String preset) {
    currentPreset = preset;
    switch (preset) {
      case 'Flat':
        gains = List.filled(10, 0.0);
        break;
      case 'Rock':
        gains = [4.0, 3.0, 0.0, -2.0, -3.0, -2.0, 0.0, 2.0, 3.0, 4.0];
        break;
      case 'Pop':
        gains = [-1.0, 1.0, 3.0, 4.0, 3.0, 0.0, -1.0, -1.0, 1.0, 2.0];
        break;
      case 'Jazz':
        gains = [3.0, 2.0, 0.0, 2.0, -2.0, -2.0, 0.0, 1.0, 2.0, 3.0];
        break;
      case 'Classical':
        gains = [4.0, 3.0, 2.0, 1.0, -1.0, -1.0, 0.0, 2.0, 3.0, 4.0];
        break;
      case 'Bass Boost':
        gains = [6.0, 5.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
        break;
      case 'Treble Boost':
        gains = [0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 3.0, 4.0, 5.0, 6.0];
        break;
      case 'Vocal':
        gains = [-2.0, -1.0, 0.0, 2.0, 4.0, 4.0, 2.0, 0.0, -1.0, -2.0];
        break;
      case 'Electronic':
        gains = [4.0, 3.0, 0.0, -2.0, -1.0, 1.0, 0.0, 1.0, 3.0, 4.0];
        break;
      default:
        // Custom - keep current gains
        break;
    }
    notifyListeners();
    _saveSettings();
  }

  void resetToDefault() {
    gains = List.filled(10, 0.0);
    volume = 1.0;
    preamp = 0.0;
    speed = 1.0;
    pitch = 1.0;
    currentPreset = 'Flat';
    notifyListeners();
    _saveSettings();
  }
}

