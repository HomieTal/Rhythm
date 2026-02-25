import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  // GitHub repository details
  static const String GITHUB_OWNER = 'HomieTal';
  static const String GITHUB_REPO = 'Rhythm';
  static const String GITHUB_API_URL = 'https://api.github.com/repos/$GITHUB_OWNER/$GITHUB_REPO/releases/latest';

  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      debugPrint('📱 Current app version: $currentVersion');
      debugPrint('🔍 Checking GitHub for updates...');

      // Fetch latest release from GitHub
      final response = await http.get(
        Uri.parse(GITHUB_API_URL),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract version from tag name (e.g., "v1.0.1" or "1.0.1")
        String latestVersion = data['tag_name'] ?? '';
        if (latestVersion.startsWith('v') || latestVersion.startsWith('V')) {
          latestVersion = latestVersion.substring(1);
        }

        debugPrint('✅ Latest GitHub release: $latestVersion');

        // Check if force update is required from release notes
        final releaseNotes = (data['body'] ?? '').toLowerCase();
        final forceUpdate = releaseNotes.contains('[force-update]') ||
                           releaseNotes.contains('force update') ||
                           releaseNotes.contains('mandatory update');

        // Get download URL from release assets
        String updateUrl = data['html_url'] ?? 'https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases';

        // Try to find APK asset for direct download
        if (data['assets'] != null && (data['assets'] as List).isNotEmpty) {
          for (var asset in data['assets']) {
            if (asset['name'].toString().toLowerCase().endsWith('.apk')) {
              updateUrl = asset['browser_download_url'];
              debugPrint('📦 Found APK: ${asset['name']}');
              break;
            }
          }
        }

        final needsUpdate = _compareVersions(currentVersion, latestVersion);

        debugPrint(needsUpdate
            ? '🔔 Update available: $currentVersion → $latestVersion'
            : '✅ App is up to date');

        return {
          'needsUpdate': needsUpdate,
          'currentVersion': currentVersion,
          'latestVersion': latestVersion,
          'forceUpdate': forceUpdate,
          'updateUrl': updateUrl,
          'releaseNotes': data['body'] ?? '',
          'releaseName': data['name'] ?? 'New Version Available',
        };
      } else {
        debugPrint('⚠️ GitHub API returned status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error checking for update: $e');
    }

    // Return no update if check fails
    return {
      'needsUpdate': false,
      'currentVersion': '0.0.0',
      'latestVersion': '0.0.0',
      'forceUpdate': false,
      'updateUrl': 'https://github.com/$GITHUB_OWNER/$GITHUB_REPO/releases',
      'releaseNotes': '',
      'releaseName': '',
    };
  }

  static bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      // Remove any non-numeric prefixes
      currentVersion = currentVersion.replaceAll(RegExp(r'[^0-9.]'), '');
      latestVersion = latestVersion.replaceAll(RegExp(r'[^0-9.]'), '');

      final current = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latest = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Ensure both lists have at least 3 elements
      while (current.length < 3) current.add(0);
      while (latest.length < 3) latest.add(0);

      for (int i = 0; i < 3; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  static Future<void> launchStore(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  static Future<bool> shouldShowUpdateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChecked = prefs.getInt('last_update_check') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check once per day (86400000 milliseconds = 24 hours)
    if (now - lastChecked > 86400000) {
      await prefs.setInt('last_update_check', now);
      return true;
    }
    return false;
  }

  static Future<void> downloadAndInstallAPK(
    String downloadUrl,
    Function(double) onProgress,
    Function(String) onError,
  ) async {
    try {
      debugPrint('📥 Starting APK download from: $downloadUrl');

      // Request storage permission for Android 13+ (if needed for older APIs)
      if (Platform.isAndroid) {
        // Android 13+ doesn't require WRITE_EXTERNAL_STORAGE for app-specific directories
        // But we need INSTALL_PACKAGES permission which is requested in manifest
        final storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
          await Permission.storage.request();
        }
      }

      // Get the app's external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create downloads folder if it doesn't exist
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '${downloadsDir.path}/Rhythm_update.apk';
      final file = File(filePath);

      // Delete old APK if exists
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted old APK');
      }

      // Download the APK with progress tracking
      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total);
            onProgress(progress);
            debugPrint('📊 Download progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      debugPrint('✅ APK downloaded successfully to: $filePath');
      onProgress(1.0);

      // Wait a moment for UI to update
      await Future.delayed(const Duration(milliseconds: 500));

      // Install the APK
      debugPrint('📲 Opening APK installer...');
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
        uti: 'public.apk',
      );

      debugPrint('Installation result: ${result.type} - ${result.message}');

      if (result.type != ResultType.done) {
        throw Exception('Failed to open installer: ${result.message}');
      }
    } catch (e) {
      debugPrint('❌ Error downloading/installing APK: $e');
      onError(e.toString());
    }
  }
}

class UpdateDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String releaseNotes;
  final String releaseName;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    this.releaseNotes = '',
    this.releaseName = 'New Version Available',
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;

  Future<void> _handleUpdate() async {
    // Check if the URL is a direct APK download
    final isDirectApk = widget.updateUrl.toLowerCase().endsWith('.apk');

    if (isDirectApk) {
      // Download and install APK automatically
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _errorMessage = null;
      });

      await UpdateService.downloadAndInstallAPK(
        widget.updateUrl,
        (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
        (error) {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _errorMessage = 'Download failed. Please try again.';
            });
          }
        },
      );
    } else {
      // Fallback to opening URL in browser
      await UpdateService.launchStore(widget.updateUrl);
      if (!widget.forceUpdate && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final dialogBgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white.withAlpha((0.6 * 255).round()) : Colors.black.withAlpha((0.6 * 255).round());

    return PopScope(
      canPop: !widget.forceUpdate && !_isDownloading,
      child: AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha((0.2 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDownloading ? Icons.downloading_rounded : Icons.system_update_rounded,
                size: 48,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isDownloading
                  ? 'Downloading Update...'
                  : (widget.forceUpdate ? 'Update Required' : 'Update Available'),
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.releaseName.isNotEmpty && !_isDownloading) ...[
              const SizedBox(height: 4),
              Text(
                widget.releaseName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDownloading) ...[
                // Download progress
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _downloadProgress,
                      backgroundColor: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.1 * 255).round()),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _downloadProgress >= 1.0
                          ? 'Opening installer...'
                          : 'Downloading APK file...',
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  widget.forceUpdate
                      ? 'A new version of Rhythm is required to continue using the app.'
                      : 'A new version of Rhythm is available with exciting new features!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                      ? Colors.white.withAlpha((0.05 * 255).round())
                      : Colors.black.withAlpha((0.05 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Version:',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            widget.currentVersion,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latest Version:',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            widget.latestVersion,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'What\'s New:',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                        ? Colors.white.withAlpha((0.05 * 255).round())
                        : Colors.black.withAlpha((0.05 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.releaseNotes,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withAlpha((0.5 * 255).round())),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: _isDownloading
            ? [] // No actions while downloading
            : [
                ElevatedButton.icon(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  label: const Text(
                    'Update Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}

