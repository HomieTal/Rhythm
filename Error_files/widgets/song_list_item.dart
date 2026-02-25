import 'package:flutter/material.dart';
import 'package:Rhythm/utils/custom_text_style.dart';

import '../model/local_song_model.dart';
import '../screen/player_screen.dart';
import '../service/audio_controller.dart';

class SongListItem extends StatefulWidget {
  final LocalSongModel song;
  final int index;

  SongListItem({super.key, required this.song, required this.index});

  @override
  State<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends State<SongListItem> {
  String _formatDuration(int milliseconds) {
    final minutes = (milliseconds / 60000).floor();
    final seconds = ((milliseconds % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audioController = AudioController();
    return ValueListenableBuilder(
      valueListenable: audioController.currentIndex,
      builder: (context, currentIndex, child) {
        return ValueListenableBuilder(
          valueListenable: audioController.isPlaying,
          builder: (context, isPlaying, child) {
            final isCurrentSong = currentIndex == widget.index;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 6,
              ),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),

                  /// --- music title --- ///
                  title: Text(
                    widget.song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: myTextStyle15(),
                  ),

                  /// --- artist --- ///
                  subtitle: Text(
                    widget.song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: myTextStyle12(fontColor: Color(0xFF4A5668)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// --- song duration --- ///
                      Text(
                        _formatDuration(widget.song.duration),
                        style: myTextStyle12(fontColor: Color(0xFF4A5668)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PlayerScreen(
                                index: widget.index,
                                song: widget.song,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          isCurrentSong && isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color:
                          isCurrentSong && isPlaying
                              ? Colors.greenAccent
                              : Colors.white54,
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    audioController.playSong(widget.index);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PlayerScreen(
                          song: widget.song,
                          index: widget.index,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
