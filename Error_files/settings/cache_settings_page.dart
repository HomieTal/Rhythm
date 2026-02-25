import 'package:flutter/material.dart';
import '../service/cache_service.dart';
import '../screen/offline_playlist_page.dart';
import '../widgets/custom_notification.dart';
import '../widgets/rhythm_dialog.dart';

class CacheSettingsPage extends StatefulWidget {
  const CacheSettingsPage({super.key});

  @override
  State<CacheSettingsPage> createState() => _CacheSettingsPageState();
}

class _CacheSettingsPageState extends State<CacheSettingsPage> {
  final CacheService _cacheService = CacheService();
  int _cacheSizeLimit = 500;
  int _currentCacheSize = 0;
  int _cachedSongsCount = 0;
  bool _isCacheEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo({bool showLoading = true}) async {
    try {
      if (showLoading && mounted) setState(() => _isLoading = true);

      await _cacheService.initialize();
      final limit = await _cacheService.getCacheSizeLimit();
      final currentSize = _cacheService.getCurrentCacheSizeMB();
      final songs = _cacheService.getCachedSongs();
      final isEnabled = await _cacheService.isCacheEnabled();

      if (mounted) {
        setState(() {
          _cacheSizeLimit = limit;
          _currentCacheSize = currentSize;
          _cachedSongsCount = songs.length;
          _isCacheEnabled = isEnabled;
          if (showLoading) _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cache info: $e');
      if (mounted && showLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateCacheSizeLimit(int newSize) async {
    try {
      await _cacheService.setCacheSizeLimit(newSize);
      await _loadCacheInfo();

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Cache size limit set to $newSize MB',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error updating cache size: $e');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Failed to update cache size',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showRhythmDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final titleColor = isDark ? Colors.white : Colors.black87;
        final bodyColor = isDark ? Colors.white70 : Colors.black54;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clear Cache',
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to clear all cached songs? This cannot be undone.',
              style: TextStyle(color: bodyColor, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    style: TextButton.styleFrom(
                      foregroundColor: bodyColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor: Colors.redAccent.withAlpha(
                        (0.14 * 255).round(),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _cacheService.clearCache();
        await _loadCacheInfo();

        if (mounted) {
          CustomNotification.show(
            context,
            message: 'Cache cleared successfully',
            icon: Icons.delete_sweep_rounded,
            color: Colors.green,
          );
        }
      } catch (e) {
        debugPrint('Error clearing cache: $e');
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'Failed to clear cache',
            icon: Icons.error_outline_rounded,
            color: Colors.red,
          );
        }
      }
    }
  }

  Future<void> _toggleCacheEnabled(bool value) async {
    try {
      await _cacheService.setCacheEnabled(value);
      if (mounted) {
        setState(() {
          _isCacheEnabled = value;
        });

        CustomNotification.show(
          context,
          message: value ? 'Cache enabled' : 'Cache disabled',
          icon: value ? Icons.check_circle_rounded : Icons.block_rounded,
          color: value ? Colors.green : Colors.orange,
        );
      }
    } catch (e) {
      debugPrint('Error toggling cache: $e');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Failed to toggle cache',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
    }
  }

  // Refresh helper: reload cache info and show a notification
  Future<void> _refreshAndNotify() async {
    try {
      // Refresh without showing the full-page loading spinner to avoid blinking
      await _loadCacheInfo(showLoading: false);
      if (!mounted) return;
      CustomNotification.show(
        context,
        message: 'refreshed cache settings',
        icon: Icons.refresh_rounded,
        color: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error refreshing cache info: $e');
    }
  }

  void _showSizeLimitDialog() {
    int tempSize = _cacheSizeLimit;

    showRhythmDialog(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).primaryColor;
        final titleColor = isDark ? Colors.white : Colors.black87;
        final bodyColor = isDark ? Colors.white70 : Colors.black54;

        return StatefulBuilder(
          builder: (buildContext, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Cache Size Limit',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cache size limit: $tempSize MB',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: tempSize.toDouble(),
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  label: '$tempSize MB',
                  activeColor: primaryColor,
                  inactiveColor: primaryColor.withAlpha((0.3 * 255).round()),
                  onChanged: (value) {
                    setDialogState(() {
                      tempSize = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '100 MB',
                      style: TextStyle(fontSize: 12, color: bodyColor),
                    ),
                    Text(
                      '5000 MB (5 GB)',
                      style: TextStyle(fontSize: 12, color: bodyColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: TextButton.styleFrom(
                          foregroundColor: bodyColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _updateCacheSizeLimit(tempSize);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Set'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : CustomScrollView(
                slivers: [
                  // Modern App Bar — removed gradient background and show icon in right corner
                  SliverAppBar(
                    expandedHeight: 120,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Icon(
                          Icons.storage_rounded,
                          size: 32,
                          color: primaryColor,
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
                      title: Text(
                        'Cache Settings',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      background: const SizedBox.shrink(),
                    ),
                  ),

                  // Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Storage Overview Card
                          _buildStorageOverviewCard(isDark, primaryColor),
                          const SizedBox(height: 20),

                          // Cache Toggle Card
                          _buildCacheToggleCard(isDark, primaryColor),
                          const SizedBox(height: 16),

                          // Quick Actions Grid
                          _buildQuickActionsGrid(isDark, primaryColor),
                          const SizedBox(height: 20),

                          // Info Card
                          _buildInfoCard(isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStorageOverviewCard(bool isDark, Color primaryColor) {
    final usagePercentage =
        _cacheSizeLimit > 0
            ? (_currentCacheSize / _cacheSizeLimit * 100).clamp(0.0, 100.0)
            : 0.0;

    Color progressColor;
    if (usagePercentage < 50) {
      progressColor = Colors.green;
    } else if (usagePercentage < 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Storage Used',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_currentCacheSize MB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: usagePercentage / 100,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${usagePercentage.toStringAsFixed(1)}% used',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                'Limit: $_cacheSizeLimit MB',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCacheToggleCard(bool isDark, Color primaryColor) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  _isCacheEnabled
                      ? primaryColor.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isCacheEnabled
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: _isCacheEnabled ? primaryColor : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Status',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCacheEnabled
                      ? 'Songs are being cached automatically'
                      : 'Caching is currently disabled',
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isCacheEnabled,
            onChanged: _toggleCacheEnabled,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isDark, Color primaryColor) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              icon: Icons.tune_rounded,
              title: 'Size Limit',
              subtitle: '$_cacheSizeLimit MB',
              color: Colors.blue,
              onTap: _showSizeLimitDialog,
              cardColor: cardColor,
              isDark: isDark,
            ),
            _buildActionCard(
              icon: Icons.music_note_rounded,
              title: 'Cached Songs',
              subtitle: '$_cachedSongsCount songs',
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfflinePlaylistPage(),
                  ),
                );
              },
              cardColor: cardColor,
              isDark: isDark,
            ),
            _buildActionCard(
              icon: Icons.delete_sweep_rounded,
              title: 'Clear Cache',
              subtitle: 'Remove all',
              color: Colors.red,
              onTap: _clearCache,
              cardColor: cardColor,
              isDark: isDark,
            ),
            _buildActionCard(
              icon: Icons.refresh_rounded,
              title: 'Refresh',
              subtitle: 'Reload info',
              color: Colors.teal,
              onTap: _refreshAndNotify,
              cardColor: cardColor,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Color cardColor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Cached songs are available for offline playback. Increase the cache limit to store more songs.',
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
