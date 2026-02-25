import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';

class NotificationPlayer extends StatefulWidget {
  const NotificationPlayer({Key? key}) : super(key: key);

  @override
  State<NotificationPlayer> createState() => _NotificationPlayerState();
}

class _NotificationPlayerState extends State<NotificationPlayer> {
  final audioController = AudioController.instance;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: audioController.currentIndex,
      builder: (context, currentIndex, _) {
        final currentSong = audioController.currentSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha((0.1 * 255).round()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.5 * 255).round()),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Album Art + Song Info + Play Button
              Row(
                children: [
                  // Album Art (Left)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF2A2A2A),
                    ),
                    child: _buildAlbumArt(currentSong),
                  ),
                  const SizedBox(width: 16),
                  // Song Info (Center)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentSong.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Play Button (Right) - Large Purple Circle
                  StreamBuilder<PlayerState>(
                    stream: audioController.audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return GestureDetector(
                        onTap: audioController.togglePlayPause,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF7B4FFF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B4FFF).withAlpha((0.4 * 255).round()),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Bottom Row: Previous + Pause + Next buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Button
                  GestureDetector(
                    onTap: audioController.previousSong,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha((0.1 * 255).round()),
                      ),
                      child: const Icon(
                        Icons.skip_previous_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Pause Button (Large Center)
                  StreamBuilder<PlayerState>(
                    stream: audioController.audioPlayer.playerStateStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data?.playing ?? false;
                      return GestureDetector(
                        onTap: audioController.togglePlayPause,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF7B4FFF),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B4FFF).withAlpha((0.5 * 255).round()),
                                blurRadius: 16,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  // Next Button
                  GestureDetector(
                    onTap: audioController.nextSong,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha((0.1 * 255).round()),
                      ),
                      child: const Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(dynamic currentSong) {
    final albumArt = currentSong.albumArt ?? '';
    final isOnlineSong = albumArt.startsWith('http://') || albumArt.startsWith('https://');

    if (isOnlineSong && albumArt.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          albumArt,
          fit: BoxFit.cover,
          width: 60,
          height: 60,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderArt();
          },
        ),
      );
    } else if (currentSong.id != null && currentSong.id > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: QueryArtworkWidget(
          id: currentSong.id,
          type: ArtworkType.AUDIO,
          artworkBorder: BorderRadius.circular(8),
          artworkWidth: 60,
          artworkHeight: 60,
          nullArtworkWidget: _buildPlaceholderArt(),
        ),
      );
    } else {
      return _buildPlaceholderArt();
    }
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7B4FFF).withAlpha((0.3 * 255).round()),
            const Color(0xFF7B4FFF).withAlpha((0.1 * 255).round()),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        color: Color(0xFF7B4FFF),
        size: 32,
      ),
    );
  }
}
