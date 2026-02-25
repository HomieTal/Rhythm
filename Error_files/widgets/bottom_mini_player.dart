import 'package:flutter/material.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/screen/player_screen.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:ui';

class BottomMiniPlayer extends StatelessWidget {
  const BottomMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = AudioController.instance;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ValueListenableBuilder(
      valueListenable: audioController.currentIndex,
      builder: (context, currentIndex, _) {
        final currentSong = audioController.currentSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        // Use unique key to force rebuild when song changes
        return Container(
          key: ValueKey('mini_player_${currentSong.id}_$currentIndex'),
          margin: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    song: currentSong,
                    index: currentIndex,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade900.withAlpha((0.4 * 255).round())
                        : Colors.grey.shade300.withAlpha((0.6 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withAlpha((0.15 * 255).round())
                          : Colors.white.withAlpha((0.5 * 255).round()),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 40,
                        spreadRadius: 0,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Album artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: currentSong.albumArt.startsWith('http')
                            ? Image.network(
                                currentSong.albumArt,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : QueryArtworkWidget(
                                id: currentSong.id,
                                type: ArtworkType.AUDIO,
                                artworkWidth: 50,
                                artworkHeight: 50,
                                artworkFit: BoxFit.cover,
                                nullArtworkWidget: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),

                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentSong.title,
                              key: ValueKey('title_${currentSong.title}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              key: ValueKey('artist_${currentSong.artist}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withAlpha((0.7 * 255).round()),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Play/Pause button
                      ValueListenableBuilder(
                        valueListenable: audioController.isPlaying,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: primaryColor,
                              size: 32,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                audioController.pauseSong();
                              } else {
                                audioController.resumeSong();
                              }
                            },
                          );
                        },
                      ),

                      // Next button
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                        onPressed: () {
                          audioController.nextSong();
                        },
                      ),
                    ],
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
