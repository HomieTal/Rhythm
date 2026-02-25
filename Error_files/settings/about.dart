import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("About", style: TextStyle(color: textColor)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAppInfoCard(),
          const SizedBox(height: 20),
          _buildSocialSection(),
          const SizedBox(height: 20),
          _buildDevelopmentSection(),
          const SizedBox(height: 20),
          _buildOthersSection(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ====== 1. App Info Card ======
  Widget _buildAppInfoCard() {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white54 : Colors.black54;
        final iconColor = isDark ? Colors.white70 : Colors.black54;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Show the app logo only (no white background) and enlarge it
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.contain,
                    width: 110,
                    height: 110,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text("Rhythm",
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 4),
              Text("v1.0.0 (Recently Updated)",
                  style: TextStyle(color: subtitleColor)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage("assets/images/developer.jpg"),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Developer",
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        Text("CrackDevelopers",
                            style: TextStyle(color: subtitleColor, fontSize: 13)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _openUrl("https://github.com/HomieTal"),
                      icon: Icon(Icons.code_rounded, color: iconColor),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // ====== 2. Social Section ======
  Widget _buildSocialSection() {
    return _buildSection(
      title: "Social",
      subtitle: "Join us on our platforms for updates, tips & discussions",
      tiles: [
        _socialTile(Icons.telegram, "Telegram", "Join the community", "https://t.me/"),
      ],
    );
  }


  // ====== 4. Development Section ======
  Widget _buildDevelopmentSection() {
    return _buildSection(
      title: "Development",
      subtitle: "See project details & contribute",
      tiles: [
        _socialTile(Icons.code, "GitHub", "View project source", "https://github.com/HomieTal/rhythm"),
        _socialTile(Icons.bug_report_outlined, "Issues / Features",
            "Report or suggest on GitHub", "https://github.com/HomieTal/rhythm/issues"),
        _socialTile(Icons.update, "Changelog", "See what's new", "https://github.com/HomieTal/rhythm/releases"),
        _socialTile(Icons.language, "Add Language",
            "Help translate this app", "https://github.com/HomieTal/rhythm"),
      ],
    );
  }

  // ====== 6. Others Section ======
  Widget _buildOthersSection() {
    return _buildSection(
      title: "Others",
      subtitle: "",
      tiles: [
        _infoTile(Icons.article_outlined, "License", "Licenses & Agreements"),
        _infoTile(Icons.info_outline, "App Version", "v1.0.0"),
        _socialTile(Icons.share_outlined, "Share Logs", "Export app logs", ""),
      ],
    );
  }

  // ====== Helper Section Builder ======
  Widget _buildSection({
    required String title,
    required String subtitle,
    List<Widget>? tiles,
    Widget? child,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white54 : Colors.black54;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 8),
                  child: Text(subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 13)),
                ),
              if (tiles != null) ...tiles,
              if (child != null) child,
            ],
          ),
        );
      }
    );
  }

  // ====== Helper Widgets ======
  Widget _socialTile(IconData icon, String title, String subtitle, String url) {
    return Builder(
      builder: (context) {
        final primaryColor = Theme.of(context).primaryColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white54 : Colors.black54;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: primaryColor),
          title: Text(title, style: TextStyle(color: textColor)),
          subtitle: Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
          onTap: url.isNotEmpty ? () => _openUrl(url) : null,
        );
      }
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Builder(
      builder: (context) {
        final primaryColor = Theme.of(context).primaryColor;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? Colors.white54 : Colors.black54;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: primaryColor),
          title: Text(title, style: TextStyle(color: textColor)),
          trailing: Text(value,
              style: TextStyle(color: subtitleColor, fontWeight: FontWeight.bold)),
        );
      }
    );
  }

  static Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
