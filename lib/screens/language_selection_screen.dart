import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm/screens/artist_selection_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final Set<String> _selectedLanguages = {};

  final List<Map<String, dynamic>> _languages = [
    {'name': 'Hindi', 'code': 'HI', 'script': 'हि', 'color': const Color(0xFF3B5998)},
    {'name': 'English', 'code': 'EN', 'script': 'EN', 'color': const Color(0xFF5A6978)},
    {'name': 'Telugu', 'code': 'TE', 'script': 'తే', 'color': const Color(0xFF2C4A6E)},
    {'name': 'Tamil', 'code': 'TA', 'script': 'த', 'color': const Color(0xFF8B4A5E)},
    {'name': 'Kannada', 'code': 'KN', 'script': 'ಕ', 'color': const Color(0xFF8B7355)},
    {'name': 'Punjabi', 'code': 'PA', 'script': 'ਪ', 'color': const Color(0xFF7D4E5E)},
    {'name': 'Bhojpuri', 'code': 'BH', 'script': 'भो', 'color': const Color(0xFF6B4A5E)},
    {'name': 'Bengali', 'code': 'BN', 'script': 'ব', 'color': const Color(0xFF3D5E6B)},
    {'name': 'Malayalam', 'code': 'ML', 'script': 'മ', 'color': const Color(0xFF6B4A5E)},
    {'name': 'Marathi', 'code': 'MR', 'script': 'म', 'color': const Color(0xFF7D4E5E)},
    {'name': 'Gujarati', 'code': 'GU', 'script': 'ગુ', 'color': const Color(0xFF2C5E6B)},
    {'name': 'Haryanvi', 'code': 'HR', 'script': 'हर', 'color': const Color(0xFF5A6978)},
    {'name': 'Urdu', 'code': 'UR', 'script': 'اردو', 'color': const Color(0xFF8B7355)},
    {'name': 'Assamese', 'code': 'AS', 'script': 'অ', 'color': const Color(0xFF7D4E5E)},
    {'name': 'Rajasthani', 'code': 'RJ', 'script': 'रा', 'color': const Color(0xFF2C4A6E)},
    {'name': 'Odia', 'code': 'OR', 'script': 'ଓ', 'color': const Color(0xFF6B4A5E)},
  ];

  Future<void> _navigateToArtistSelection() async {
    if (_selectedLanguages.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Language Required',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Please select at least one language',
            style: TextStyle(
              color: Colors.white.withAlpha((0.7 * 255).round()),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFFE94560)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_languages', _selectedLanguages.toList());

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArtistSelectionScreen(
            selectedLanguages: _selectedLanguages.toList(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'What music do you like?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select music languages in the order of preference',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),

            // Language Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = _selectedLanguages.contains(language['name']);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedLanguages.remove(language['name']);
                          } else {
                            _selectedLanguages.add(language['name']);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: language['color'],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFFE94560),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Script in background
                            Positioned(
                              right: 16,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  language['script'],
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withAlpha((0.2 * 255).round()),
                                  ),
                                ),
                              ),
                            ),
                            // Language name
                            Positioned(
                              left: 16,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Text(
                                  language['name'],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Selected indicator
                            if (isSelected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE94560),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _navigateToArtistSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLanguages.isNotEmpty
                        ? const Color(0xFFE94560)
                        : const Color(0xFF2C3E50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _selectedLanguages.isNotEmpty
                          ? Colors.white
                          : Colors.white.withAlpha((0.5 * 255).round()),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

