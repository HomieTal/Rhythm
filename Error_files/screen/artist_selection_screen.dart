import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Rhythm/screen/home_screen.dart';

class ArtistSelectionScreen extends StatefulWidget {
  final List<String> selectedLanguages;

  const ArtistSelectionScreen({
    super.key,
    required this.selectedLanguages,
  });

  @override
  State<ArtistSelectionScreen> createState() => _ArtistSelectionScreenState();
}

class _ArtistSelectionScreenState extends State<ArtistSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedArtists = {};
  String _searchQuery = '';
  bool _showAllArtists = true;

  // Comprehensive list of artists with DiceBear Avatars (better than text-only)
  final List<Map<String, String>> _allArtists = [
    {'name': 'Arijit Singh', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=ArijitSingh&backgroundColor=E94560'},
    {'name': 'Shreya Ghoshal', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=ShreyaGhoshal&backgroundColor=667EEA'},
    {'name': 'A. R. Rahman', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=ARRahman&backgroundColor=F59E0B'},
    {'name': 'Neha Kakkar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=NehaKakkar&backgroundColor=EC4899'},
    {'name': 'Sonu Nigam', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SonuNigam&backgroundColor=10B981'},
    {'name': 'Atif Aslam', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=AtifAslam&backgroundColor=8B5CF6'},
    {'name': 'Badshah', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Badshah&backgroundColor=EF4444'},
    {'name': 'Guru Randhawa', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=GuruRandhawa&backgroundColor=3B82F6'},
    {'name': 'Diljit Dosanjh', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=DiljitDosanjh&backgroundColor=F97316'},
    {'name': 'Yo Yo Honey Singh', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=HoneySingh&backgroundColor=06B6D4'},
    {'name': 'Jubin Nautiyal', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=JubinNautiyal&backgroundColor=84CC16'},
    {'name': 'Armaan Malik', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=ArmaanMalik&backgroundColor=A855F7'},
    {'name': 'Darshan Raval', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=DarshanRaval&backgroundColor=14B8A6'},
    {'name': 'Tony Kakkar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=TonyKakkar&backgroundColor=F43F5E'},
    {'name': 'Tulsi Kumar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=TulsiKumar&backgroundColor=6366F1'},
    {'name': 'Sunidhi Chauhan', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SunidhiChauhan&backgroundColor=D946EF'},
    {'name': 'Dhvani Bhanushali', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=DhvaniBhanushali&backgroundColor=22C55E'},
    {'name': 'Harrdy Sandhu', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=HarrdySandhu&backgroundColor=7C3AED'},
    {'name': 'Jasleen Royal', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=JasleenRoyal&backgroundColor=DC2626'},
    {'name': 'Pritam', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Pritam&backgroundColor=2563EB'},
    {'name': 'Vishal-Shekhar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=VishalShekhar&backgroundColor=EA580C'},
    {'name': 'Sachin-Jigar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SachinJigar&backgroundColor=0891B2'},
    {'name': 'Tanishk Bagchi', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=TanishkBagchi&backgroundColor=65A30D'},
    {'name': 'Anirudh Ravichander', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnirudhR&backgroundColor=9333EA'},
    {'name': 'Sid Sriram', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SidSriram&backgroundColor=0D9488'},
    {'name': 'Anirudh', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Anirudh&backgroundColor=E11D48'},
    {'name': 'Devi Sri Prasad', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=DeviSriPrasad&backgroundColor=4F46E5'},
    {'name': 'S. P. Balasubrahmanyam', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SPB&backgroundColor=C026D3'},
    {'name': 'K. S. Chithra', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=KSChithra&backgroundColor=16A34A'},
    {'name': 'Shankar Mahadevan', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=ShankarM&backgroundColor=6D28D9'},
    {'name': 'Kailash Kher', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=KailashKher&backgroundColor=B91C1C'},
    {'name': 'Mohit Chauhan', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=MohitChauhan&backgroundColor=1D4ED8'},
    {'name': 'Shaan', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Shaan&backgroundColor=C2410C'},
    {'name': 'KK', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=KK&backgroundColor=0E7490'},
    {'name': 'Rahat Fateh Ali Khan', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=RahatAliKhan&backgroundColor=4D7C0F'},
    {'name': 'B Praak', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=BPraak&backgroundColor=7E22CE'},
    {'name': 'Jaani', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jaani&backgroundColor=047857'},
    {'name': 'Gippy Grewal', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=GippyGrewal&backgroundColor=BE123C'},
    {'name': 'Ammy Virk', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=AmmyVirk&backgroundColor=3730A3'},
    {'name': 'Sidhu Moose Wala', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=SidhuMooseWala&backgroundColor=A21CAF'},
    {'name': 'AP Dhillon', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=APDhillon&backgroundColor=15803D'},
    {'name': 'Karan Aujla', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=KaranAujla&backgroundColor=5B21B6'},
    {'name': 'Divine', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Divine&backgroundColor=991B1B'},
    {'name': 'Naezy', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Naezy&backgroundColor=1E40AF'},
    {'name': 'Raftaar', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Raftaar&backgroundColor=9A3412'},
    {'name': 'Emiway Bantai', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=EmiwayBantai&backgroundColor=155E75'},
    {'name': 'Ritviz', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Ritviz&backgroundColor=3F6212'},
    {'name': 'Nucleya', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=Nucleya&backgroundColor=6B21A8'},
    {'name': 'Prateek Kuhad', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=PrateekKuhad&backgroundColor=065F46'},
    {'name': 'Anuv Jain', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnuvJain&backgroundColor=9F1239'},
    {'name': 'When Chai Met Toast', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=WCMT&backgroundColor=312E81'},
    {'name': 'The Local Train', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=LocalTrain&backgroundColor=86198F'},
    {'name': 'Lisa Mishra', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=LisaMishra&backgroundColor=166534'},
    {'name': 'Ananya Birla', 'image': 'https://api.dicebear.com/7.x/avataaars/svg?seed=AnanyaBirla&backgroundColor=581C87'},
  ];

  List<Map<String, String>> get _filteredArtists {
    if (_searchQuery.isEmpty) {
      return _allArtists;
    }
    return _allArtists
        .where((artist) => artist['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setStringList('selected_artists', _selectedArtists.toList());

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const RhythmHome(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
            (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Pick 3 or more artists you like',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2942),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search Artist',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha((0.4 * 255).round()),
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withAlpha((0.4 * 255).round()),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('All', _showAllArtists, () {
                    setState(() {
                      _showAllArtists = true;
                    });
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Trending', !_showAllArtists, () {
                    setState(() {
                      _showAllArtists = false;
                    });
                  }),
                ],
              ),
            ),

            // Artists List - Two Column Layout
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: (_filteredArtists.length / 2).ceil(),
                itemBuilder: (context, rowIndex) {
                  final leftIndex = rowIndex * 2;
                  final rightIndex = leftIndex + 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Left Artist
                        Expanded(
                          child: _buildArtistItem(
                            _filteredArtists[leftIndex],
                            _selectedArtists.contains(_filteredArtists[leftIndex]['name']),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Right Artist (if exists)
                        if (rightIndex < _filteredArtists.length)
                          Expanded(
                            child: _buildArtistItem(
                              _filteredArtists[rightIndex],
                              _selectedArtists.contains(_filteredArtists[rightIndex]['name']),
                            ),
                          )
                        else
                          const Expanded(child: SizedBox()),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedArtists.length >= 3
                      ? _completeOnboarding
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedArtists.length >= 3
                        ? const Color(0xFFE94560)
                        : const Color(0xFF1A2942),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: const Color(0xFF1A2942),
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _selectedArtists.length >= 3
                          ? Colors.white
                          : Colors.white.withAlpha((0.3 * 255).round()),
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

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1A2942),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0A1628) : Colors.white.withAlpha((0.7 * 255).round()),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildArtistItem(Map<String, String> artist, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedArtists.remove(artist['name']);
          } else {
            _selectedArtists.add(artist['name']!);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3A5F)
              : const Color(0xFF1A2942),
          borderRadius: BorderRadius.circular(25),
          border: isSelected
              ? Border.all(
            color: Colors.white.withAlpha((0.3 * 255).round()),
            width: 1,
          )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Artist Image - Now showing actual image or placeholder
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((0.1 * 255).round()),
              ),
              child: ClipOval(
                child: artist['image'] != null && artist['image']!.isNotEmpty
                    ? Image.network(
                  artist['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                    );
                  },
                )
                    : Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.white.withAlpha((0.6 * 255).round()),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Artist Name
            Expanded(
              child: Text(
                artist['name']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Selected indicator
            if (isSelected) ...[
              const SizedBox(width: 4),
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF0A1628),
                  size: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

