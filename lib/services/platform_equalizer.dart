import 'dart:async';
import 'package:flutter/services.dart';

class PlatformEqualizer {
  static const MethodChannel _channel = MethodChannel('rhythm.equalizer');

  /// Set the 5 band gains (in dB). Expects a list of 5 doubles in order [60,230,910,4k,14k].
  static Future<void> setGains(List<double> gains) async {
    try {
      await _channel.invokeMethod('setGains', {'gains': gains});
    } catch (e) {
      // Don't crash if platform not available
      // ignore: avoid_print
      print('PlatformEqualizer.setGains error: $e');
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setEnabled', {'enabled': enabled});
    } catch (e) {
      // ignore
      print('PlatformEqualizer.setEnabled error: $e');
    }
  }

  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } catch (e) {
      // ignore
    }
  }
}

