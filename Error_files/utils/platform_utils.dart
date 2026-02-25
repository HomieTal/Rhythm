import 'package:flutter/services.dart';

class PlatformUtils {
  static const platform = MethodChannel('com.example.rhythm/platform');

  /// Move the app to background (Android only)
  static Future<void> moveToBackground() async {
    try {
      await platform.invokeMethod('moveToBackground');
    } on PlatformException catch (e) {
      print("Failed to move to background: '${e.message}'.");
    }
  }
}

