import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/settings/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.dynamicColor;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Appearance',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          _buildSectionHeader('Theme Mode', textColor),
          const SizedBox(height: 12),
          _buildThemeModeSelector(themeProvider, isDark, primaryColor),

          const SizedBox(height: 32),

          // Navigation Style Section
          _buildSectionHeader('Navigation Style', textColor),
          const SizedBox(height: 12),
          _buildNavigationStyleSelector(themeProvider, isDark, primaryColor),

          const SizedBox(height: 32),

          // Accent Color Section
          _buildSectionHeader('Accent Color', textColor),
          const SizedBox(height: 12),
          _buildColorPicker(themeProvider, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildThemeModeSelector(ThemeProvider themeProvider, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildThemeOption(
            'Light',
            Icons.wb_sunny_rounded,
            !themeProvider.isDarkMode && !themeProvider.useSystemTheme,
            () {
              themeProvider.toggleSystemTheme(false);
              themeProvider.toggleDarkMode(false);
            },
            isDark,
            primaryColor,
          ),
          _buildThemeOption(
            'System',
            Icons.brightness_6_rounded,
            themeProvider.useSystemTheme,
            () {
              themeProvider.toggleSystemTheme(true);
            },
            isDark,
            primaryColor,
          ),
          _buildThemeOption(
            'Dark',
            Icons.nightlight_round,
            themeProvider.isDarkMode && !themeProvider.useSystemTheme,
            () {
              themeProvider.toggleSystemTheme(false);
              themeProvider.toggleDarkMode(true);
            },
            isDark,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationStyleSelector(ThemeProvider themeProvider, bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildNavOption(
            'Bottom Nav',
            Icons.view_agenda_rounded,
            themeProvider.useBottomNav,
            () => themeProvider.toggleBottomNav(true),
            isDark,
            primaryColor,
          ),
          _buildNavOption(
            'Sidebar',
            Icons.view_sidebar_rounded,
            !themeProvider.useBottomNav,
            () => themeProvider.toggleBottomNav(false),
            isDark,
            primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNavOption(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
    bool isDark,
    Color primaryColor,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(ThemeProvider themeProvider, bool isDark, Color primaryColor) {
    final colors = [
      Colors.deepPurple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.pink,
      Colors.indigo,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = themeProvider.dynamicColor == color;
            return GestureDetector(
              onTap: () => themeProvider.setDynamicColor(color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: isSelected
                      ? [BoxShadow(color: color.withAlpha((0.5 * 255).round()), blurRadius: 10)]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick a color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: themeProvider.dynamicColor,
                    onColorChanged: (color) {
                      themeProvider.setDynamicColor(color);
                    },
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
          icon: const Icon(Icons.color_lens_outlined),
          label: const Text('Custom Color'),
        ),
      ],
    );
  }
}

