import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// A safe wrapper for QueryArtworkWidget that handles "Reply already submitted" crashes
/// by catching errors and showing a fallback widget instead of crashing the app.
class SafeArtworkWidget extends StatefulWidget {
  final int id;
  final ArtworkType type;
  final Widget? nullArtworkWidget;
  final BorderRadius? artworkBorder;
  final double artworkWidth;
  final double artworkHeight;
  final BoxFit artworkFit;
  final int? quality;
  final int? size;

  const SafeArtworkWidget({
    super.key,
    required this.id,
    required this.type,
    this.nullArtworkWidget,
    this.artworkBorder,
    this.artworkWidth = 48,
    this.artworkHeight = 48,
    this.artworkFit = BoxFit.cover,
    this.quality,
    this.size,
  });

  @override
  State<SafeArtworkWidget> createState() => _SafeArtworkWidgetState();
}

class _SafeArtworkWidgetState extends State<SafeArtworkWidget> {
  bool _hasError = false;
  static final Set<int> _failedIds = {}; // Cache failed IDs to avoid repeated failures

  @override
  void initState() {
    super.initState();
    // Check if this ID previously failed
    _hasError = _failedIds.contains(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    // If we already know this ID fails, show fallback immediately
    if (_hasError) {
      return _buildFallback();
    }

    return QueryArtworkWidget(
      id: widget.id,
      type: widget.type,
      artworkBorder: widget.artworkBorder ?? BorderRadius.circular(8),
      artworkWidth: widget.artworkWidth,
      artworkHeight: widget.artworkHeight,
      artworkFit: widget.artworkFit,
      quality: widget.quality ?? 100,
      size: widget.size ?? 200,
      nullArtworkWidget: widget.nullArtworkWidget ?? _buildFallback(),
      errorBuilder: (context, error, stackTrace) {
        // Log the error but don't crash
        debugPrint('⚠️ SafeArtworkWidget error for id ${widget.id}: $error');

        // Cache this ID as failed
        _failedIds.add(widget.id);

        // Schedule state update after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });

        return _buildFallback();
      },
    );
  }

  Widget _buildFallback() {
    return widget.nullArtworkWidget ?? Container(
      width: widget.artworkWidth,
      height: widget.artworkHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: widget.artworkBorder ?? BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white54,
        size: 24,
      ),
    );
  }
}

