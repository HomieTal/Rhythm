import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rhythm/services/audio_controller.dart';

class SleepTimerService {
  static final SleepTimerService instance = SleepTimerService._();
  SleepTimerService._();

  final ValueNotifier<bool> isActive = ValueNotifier(false);
  final ValueNotifier<Duration> remaining = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> totalDuration = ValueNotifier(Duration.zero);

  Timer? _internalTimer;

  void _cancelInternalTimer() {
    try {
      _internalTimer?.cancel();
    } catch (_) {}
    _internalTimer = null;
  }

  void start(Duration duration) {
    // Start or restart the sleep timer; run in service so it persists across UI navigation
    debugPrint('🕐 Sleep Timer started: ${duration.inMinutes} minutes');
    totalDuration.value = duration;
    remaining.value = duration;
    isActive.value = true;
    debugPrint('🕐 Sleep Timer isActive set to: ${isActive.value}');

    _cancelInternalTimer();
    _internalTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final secs = remaining.value.inSeconds;
      if (secs > 1) {
        remaining.value = Duration(seconds: secs - 1);
      } else {
        // time up
        remaining.value = Duration.zero;
        isActive.value = false;
        _cancelInternalTimer();
        // Pause audio
        try {
          AudioController.instance.pauseSong();
        } catch (e) {
          // ignore
        }
      }
    });
  }

  void update(Duration duration) {
    // allow external updates (not typically used)
    remaining.value = duration;
  }

  void stop() {
    isActive.value = false;
    remaining.value = Duration.zero;
    totalDuration.value = Duration.zero;
    _cancelInternalTimer();
  }
}
