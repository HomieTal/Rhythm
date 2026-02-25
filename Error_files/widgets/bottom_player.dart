import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:ui';
import '../screen/player_screen.dart';
import '../service/audio_controller.dart';

class BottomPlayer extends StatelessWidget {
  const BottomPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = AudioController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ValueListenableBuilder(
      valueListenable: audioController.currentIndex,
      builder: (context, currentIndex, _) {
        final currentSong = audioController.currentSong;
        if (currentSong == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlayerScreen(song: currentSong, index: currentIndex),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withAlpha((0.7 * 255).round())
                      : Colors.white.withAlpha((0.85 * 255).round()),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    topLeft: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withAlpha((0.15 * 255).round())
                          : Colors.black.withAlpha((0.1 * 255).round()),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.3 * 255).round()),
                      offset: const Offset(0, -10),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                // Progress bar at the top
                StreamBuilder<Duration>(
                  stream: audioController.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration =
                        audioController.audioPlayer.duration ?? Duration.zero;
                    return Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: ProgressBar(
                        progress: position,
                        total: duration,
                        progressBarColor: primaryColor,
                        baseBarColor: isDark
                            ? Colors.white.withAlpha((0.2 * 255).round())
                            : Colors.black.withAlpha((0.1 * 255).round()),
                        bufferedBarColor: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.05 * 255).round()),
                        thumbColor: primaryColor,
                        barHeight: 2,
                        thumbRadius: 0,
                        timeLabelLocation: TimeLabelLocation.none,
                        onSeek: (duration) {
                          audioController.audioPlayer.seek(duration);
                        },
                      ),
                    );
                  },
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      // Album artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
                          id: currentSong.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.circular(8),
                          artworkWidth: 56,
                          artworkHeight: 56,
                          nullArtworkWidget: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: primaryColor,
                              size: 28,
                            ),
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
                              currentSong.title.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white.withAlpha((0.6 * 255).round())
                                    : Colors.black.withAlpha((0.6 * 255).round()),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Control buttons in rounded container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha((0.1 * 255).round())
                              : Colors.black.withAlpha((0.05 * 255).round()),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Previous button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha((0.8 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: audioController.previousSong,
                                icon: const Icon(
                                  Icons.skip_previous_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Pause/Play button
                            StreamBuilder<PlayerState>(
                              stream:
                              audioController.audioPlayer.playerStateStream,
                              builder: (context, snapshot) {
                                final playerState = snapshot.data;
                                final processingState =
                                    playerState?.processingState;
                                final playing = playerState?.playing;

                                if (processingState ==
                                    ProcessingState.loading ||
                                    processingState ==
                                        ProcessingState.buffering) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          primaryColor,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: audioController.togglePlayPause,
                                    icon: Icon(
                                      playing == true
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isDark ? Colors.black : Colors.white,
                                      size: 22,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),

                            // Next button
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha((0.8 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: audioController.nextSong,
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  },
);
}
}