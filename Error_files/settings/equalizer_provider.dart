import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple 5-band equalizer state manager.
/// Bands are roughly: 60Hz, 230Hz, 910Hz, 3600Hz, 14000Hz
class EqualizerProvider extends ChangeNotifier {
  static const String _prefsKey = 'equalizer_gains_v1';
  static const String _prefsEnabledKey = 'equalizer_enabled_v1';
  static const String _prefsPreampKey = 'equalizer_preamp_v1';
  static const String _prefsPitchKey = 'equalizer_pitch_v1';
  static const String _prefsSpeedKey = 'equalizer_speed_v1';
  static const String _prefsVolumeKey = 'equalizer_volume_v1';
  static const String _prefsMutedKey = 'equalizer_muted_v1';

  // Gains in dB, default 0.0 for all bands
  final List<double> _gains = List<double>.filled(5, 0.0);
  bool _enabled = true;
  double _preamp = 0.0; // dB
  double _pitch = 1.0; // multiplier
  double _speed = 1.0; // multiplier
  double _volume = 1.0; // multiplier
  bool _muted = false;
  double? _lastVolumeBeforeMute;

  EqualizerProvider() {
    _loadFromPrefs();
    _loadEnabledFromPrefs();
    _loadControlsFromPrefs();
  }

  List<double> get gains => List.unmodifiable(_gains);

  bool get enabled => _enabled;

  double get preamp => _preamp;
  double get pitch => _pitch;
  double get speed => _speed;
  double get volume => _volume;
  bool get muted => _muted;

  double gainAt(int index) {
    if (index < 0 || index >= _gains.length) return 0.0;
    return _gains[index];
  }

  Future<void> setGain(int index, double value, {bool persist = true}) async {
    if (index < 0 || index >= _gains.length) return;
    _gains[index] = value;
    notifyListeners();
    if (persist) await _saveToPrefs();
  }

  Future<void> setAllGains(List<double> values, {bool persist = true}) async {
    final len = _gains.length;
    for (var i = 0; i < len && i < values.length; i++) {
      _gains[i] = values[i];
    }
    notifyListeners();
    if (persist) await _saveToPrefs();
  }

  // Controls setters
  Future<void> setPreamp(double v, {bool persist = true}) async {
    _preamp = v;
    notifyListeners();
    if (persist) await _saveControlsToPrefs();
  }

  Future<void> setPitch(double v, {bool persist = true}) async {
    _pitch = v;
    notifyListeners();
    if (persist) await _saveControlsToPrefs();
  }

  Future<void> setSpeed(double v, {bool persist = true}) async {
    _speed = v;
    notifyListeners();
    if (persist) await _saveControlsToPrefs();
  }

  Future<void> setVolume(double v, {bool persist = true}) async {
    _volume = v;
    // if user sets volume > 0 while muted, unmute
    if (_muted && _volume > 0) {
      _muted = false;
      _lastVolumeBeforeMute = null;
      if (persist) await _saveMutedToPrefs();
    }
    notifyListeners();
    if (persist) await _saveControlsToPrefs();
  }

  Future<void> setMuted(bool m, {bool persist = true}) async {
    if (m == _muted) return;
    _muted = m;
    if (_muted) {
      // store last volume and set volume to 0
      _lastVolumeBeforeMute = _volume;
      _volume = 0.0;
    } else {
      // restore previous volume if available
      _volume = _lastVolumeBeforeMute ?? 1.0;
      _lastVolumeBeforeMute = null;
    }
    notifyListeners();
    if (persist) await _saveControlsToPrefs();
    if (persist) await _saveMutedToPrefs();
  }

  Future<void> toggleMute({bool persist = true}) async {
    await setMuted(!_muted, persist: persist);
  }

  Future<void> reset() async {
    for (var i = 0; i < _gains.length; i++) {
      _gains[i] = 0.0;
    }
    notifyListeners();
    await _saveToPrefs();
  }

  /// Reset gains and controls to defaults
  Future<void> resetAll() async {
    await reset();
    _preamp = 0.0;
    _pitch = 1.0;
    _speed = 1.0;
    _volume = 1.0;
    // clear mute state on reset
    _muted = false;
    _lastVolumeBeforeMute = null;
    notifyListeners();
    await _saveControlsToPrefs();
    await _saveMutedToPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey);
      if (list != null && list.length == _gains.length) {
        for (var i = 0; i < _gains.length; i++) {
          final parsed = double.tryParse(list[i]);
          if (parsed != null) _gains[i] = parsed;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load equalizer settings: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _gains.map((e) => e.toString()).toList();
      await prefs.setStringList(_prefsKey, list);
    } catch (e) {
      debugPrint('Failed to save equalizer settings: $e');
    }
  }

  Future<void> _loadControlsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preamp = prefs.getDouble(_prefsPreampKey) ?? 0.0;
      _pitch = prefs.getDouble(_prefsPitchKey) ?? 1.0;
      _speed = prefs.getDouble(_prefsSpeedKey) ?? 1.0;
      _volume = prefs.getDouble(_prefsVolumeKey) ?? 1.0;
      _muted = prefs.getBool(_prefsMutedKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load equalizer controls: $e');
    }
  }

  Future<void> _saveControlsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefsPreampKey, _preamp);
      await prefs.setDouble(_prefsPitchKey, _pitch);
      await prefs.setDouble(_prefsSpeedKey, _speed);
      await prefs.setDouble(_prefsVolumeKey, _volume);
    } catch (e) {
      debugPrint('Failed to save equalizer controls: $e');
    }
  }

  Future<void> _saveMutedToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsMutedKey, _muted);
    } catch (e) {
      debugPrint('Failed to save equalizer muted flag: $e');
    }
  }

  // --- enabled flag persistence
  Future<void> _loadEnabledFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_prefsEnabledKey) ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load equalizer enabled flag: $e');
    }
  }

  Future<void> _saveEnabledToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsEnabledKey, _enabled);
    } catch (e) {
      debugPrint('Failed to save equalizer enabled flag: $e');
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    await _saveEnabledToPrefs();
  }

  Future<void> toggleEnabled() async {
    _enabled = !_enabled;
    notifyListeners();
    await _saveEnabledToPrefs();
  }
}
