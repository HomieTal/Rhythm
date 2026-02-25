import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  bool _hapticEnabled = true;

  void _triggerHaptic() {
    if (_hapticEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  // Enhanced Color picker dialog with HSV picker
  void _showColorPicker(BuildContext context, ThemeProvider themeProvider) {
    Color selectedColor = themeProvider.dynamicColor;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                "Pick a Theme Color",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HSV Color Picker with Wheel
                    ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      colorPickerWidth: 300,
                      pickerAreaHeightPercent: 0.7,
                      enableAlpha: false,
                      displayThumbColor: true,
                      paletteType: PaletteType.hsvWithHue,
                      labelTypes: const [],
                      pickerAreaBorderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 16),
                    // Color preview
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedColor,
                    foregroundColor: _getContrastColor(selectedColor),
                  ),
                  onPressed: () {
                    themeProvider.setDynamicColor(selectedColor);
                    Navigator.pop(context);
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to get contrasting color for text
  Color _getContrastColor(Color color) {
    return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Get actual current brightness considering system theme
    final Brightness currentBrightness;
    if (themeProvider.useSystemTheme) {
      currentBrightness = MediaQuery.of(context).platformBrightness;
    } else {
      currentBrightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
    }

    final isDark = currentBrightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    // Determine current theme mode
    String themeMode = themeProvider.useSystemTheme
        ? "system"
        : (themeProvider.isDarkMode ? "dark" : "light");

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Theme",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined, color: isDark ? Colors.white : Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          // Header
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade300.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: Colors.pink.shade300,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Theme",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "The overall vibe of your player",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Theme Mode Selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade300.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.brightness_4_outlined,
                        color: Colors.blue.shade300,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Theme Mode",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _themeButton("Auto", "system", Icons.settings_suggest_outlined, themeMode, themeProvider, isDark),
                      _themeButton("Light", "light", Icons.brightness_7_outlined, themeMode, themeProvider, isDark),
                      _themeButton("Dark", "dark", Icons.brightness_4_outlined, themeMode, themeProvider, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Bar Toggle
          _buildSettingsTile(
            context,
            icon: Icons.navigation_rounded,
            title: "Show Navigation Bar",
            subtitle: "Use bottom navigation bar instead of side drawer",
            value: themeProvider.useBottomNav,
            onChanged: (val) {
              themeProvider.toggleBottomNav(val);
              _triggerHaptic();
            },
            color: Colors.teal.shade300,
          ),

          // COMMENTED OUT - Auto Coloring Toggle (feature disabled)
          // _buildSettingsTile(
          //   context,
          //   icon: Icons.palette_outlined,
          //   title: "Auto Coloring",
          //   subtitle:
          //   "Automatically pick player colors from current artwork.\nMight affect performance",
          //   value: themeProvider.autoColoring,
          //   onChanged: (val) {
          //     themeProvider.toggleAutoColoring(val);
          //     _triggerHaptic();
          //   },
          //   color: Colors.purple.shade300,
          // ),

          // Default Color Picker
          GestureDetector(
            onTap: () => _showColorPicker(context, themeProvider),
            child: _buildColorTile(
              context,
              icon: Icons.palette_outlined,
              title: "Default Color",
              subtitle: "Set a color to be used by the player",
              color: themeProvider.dynamicColor,
            ),
          ),

          // Language
          _buildSettingsTile(
            context,
            icon: Icons.language_outlined,
            title: "Language",
            subtitle: null,
            trailing: "English",
            color: Colors.orange.shade300,
          ),
        ],
      ),
    );
  }

  // Theme mode button - Optimized for instant response
  Widget _themeButton(
      String label,
      String mode,
      IconData icon,
      String selectedMode,
      ThemeProvider provider,
      bool isDark,
      ) {
    final isSelected = selectedMode == mode;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _triggerHaptic();
            // Use setState to update immediately for visual feedback
            setState(() {
              if (mode == 'system') {
                provider.toggleSystemTheme(true);
              } else {
                provider.toggleSystemTheme(false);
                provider.toggleDarkMode(mode == 'dark');
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? provider.dynamicColor.withAlpha((0.6 * 255).round())
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? _getContrastColor(provider.dynamicColor)
                      : (isDark ? Colors.white70 : Colors.black54),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? _getContrastColor(provider.dynamicColor)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Settings Tile - Optimized for instant response
  Widget _buildSettingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? subtitle,
        bool? value,
        ValueChanged<bool>? onChanged,
        required Color color,
        String? trailing,
      }) {
    // Calculate colors once, outside build
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final Brightness currentBrightness;
    if (themeProvider.useSystemTheme) {
      currentBrightness = MediaQuery.of(context).platformBrightness;
    } else {
      currentBrightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
    }

    final isDark = currentBrightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  child: Text(title),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitleColor,
                      height: 1.4,
                    ),
                    child: Text(subtitle),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              activeTrackColor: color.withAlpha((0.14 * 255).round()),
            )
          else if (trailing != null)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(fontSize: 14, color: subtitleColor),
              child: Text(trailing),
            ),
        ],
      ),
    );
  }

  // Color Tile UI
  Widget _buildColorTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    )),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: subtitleColor)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
          ),
        ],
      ),
    );
  }
}