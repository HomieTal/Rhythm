import 'package:flutter/material.dart';

class GenresPage extends StatelessWidget {
  const GenresPage({super.key});

  final List<Map<String, dynamic>> genres = const [
    {'name': 'Pop', 'icon': Icons.audiotrack},
    {'name': 'Rock', 'icon': Icons.music_note},
    {'name': 'Jazz', 'icon': Icons.library_music},
    {'name': 'Hip Hop', 'icon': Icons.headset},
    {'name': 'Classical', 'icon': Icons.album},
    {'name': 'Electronic', 'icon': Icons.surround_sound},
    {'name': 'Reggae', 'icon': Icons.queue_music},
    {'name': 'Country', 'icon': Icons.mic},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Genres'),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          itemCount: genres.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final genre = genres[index];
            return GestureDetector(
              onTap: () {
                // Navigate to songs of this genre
                // Navigator.push(context, MaterialPageRoute(builder: (_) => GenreSongsPage(genre: genre['name'])));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(128, 0, 128, 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      genre['icon'],
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      genre['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
