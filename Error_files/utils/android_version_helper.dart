import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class for Android version-specific functionality
class AndroidVersionHelper {
  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Request appropriate audio permissions based on Android version
  /// Tries different permission strategies for compatibility
  static Future<bool> requestStoragePermissions() async {
    try {
      if (!isAndroid) return true;

      // Try requesting audio permission first (Android 13+)
      var audioStatus = await Permission.audio.request();
      if (audioStatus.isGranted) return true;

      // Try storage permission (Android 6-12)
      var storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;

      // Check if we have any media permissions
      var mediaStatus = await Permission.mediaLibrary.request();
      if (mediaStatus.isGranted) return true;

      // If at least one permission is granted or permanently denied, continue
      return audioStatus.isGranted ||
             storageStatus.isGranted ||
             mediaStatus.isGranted ||
             audioStatus.isPermanentlyDenied ||
             storageStatus.isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      // Don't block the app if permission request fails
      return true;
    }
  }

  /// Check audio permission status
  static Future<bool> checkStoragePermission() async {
    try {
      if (!isAndroid) return true;

      // Check multiple permission types for compatibility
      final audioGranted = await Permission.audio.isGranted;
      final storageGranted = await Permission.storage.isGranted;
      final mediaGranted = await Permission.mediaLibrary.isGranted;

      return audioGranted || storageGranted || mediaGranted;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Open app settings for permission management
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
  }

  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Settings'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Handle permission denial with appropriate action
  static Future<void> handlePermissionDenial(BuildContext context) async {
    final shouldOpenSettings = await showPermissionRationale(
      context,
      title: 'Permission Required',
      message: 'Rhythm needs storage permission to access your music files. '
          'Please grant the permission in app settings.',
    );

    if (shouldOpenSettings) {
      await openAppSettings();
    }
  }
}

