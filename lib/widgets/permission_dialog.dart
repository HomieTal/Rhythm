import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

class PermissionDialog {
  static Future<bool> requestAudioPermission(BuildContext context) async {
    // Check if permission is already granted
    final status = await Permission.audio.status;
    debugPrint('PermissionDialog: Current permission status: $status');

    if (status.isGranted) {
      debugPrint('PermissionDialog: Permission already granted');
      return true;
    }

    // If permission is permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      debugPrint('PermissionDialog: Permission permanently denied, showing settings dialog');
      await _showSettingsDialog(context);
      return false;
    }

    // Try to request permission directly first
    debugPrint('PermissionDialog: Requesting audio permission from system...');
    final result = await Permission.audio.request();
    debugPrint('PermissionDialog: System permission result: $result');

    // If granted, return true
    if (result.isGranted) {
      debugPrint('PermissionDialog: Permission granted');
      return true;
    }

    // If permanently denied after request, show settings dialog
    if (result.isPermanentlyDenied) {
      debugPrint('PermissionDialog: Permission permanently denied, showing settings dialog');
      await _showSettingsDialog(context);
      return false;
    }

    // If denied but not permanently, user can try again
    debugPrint('PermissionDialog: Permission denied');
    return false;
  }

  static Future<void> _showSettingsDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1a1a2e),
                          const Color(0xFF16213e),
                        ]
                      : [
                          const Color(0xFFf0f4f8),
                          const Color(0xFFe2e8f0),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha((0.1 * 255).round())
                      : Colors.black.withAlpha((0.1 * 255).round()),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withAlpha((0.3 * 255).round())
                          : Colors.white.withAlpha((0.8 * 255).round()),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          color: primaryColor,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Permission Required',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Audio permission is permanently denied. Please go to Settings to enable it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  openAppSettings();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Open Settings'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

