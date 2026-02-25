import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:rhythm/services//sleep_timer_service.dart';

class SleepTimerPage extends StatefulWidget {
  const SleepTimerPage({super.key});

  @override
  State<SleepTimerPage> createState() => _SleepTimerPageState();
}

class _SleepTimerPageState extends State<SleepTimerPage> with SingleTickerProviderStateMixin {
  Duration _selectedDuration = const Duration(minutes: 15);
  Duration _remainingDuration = Duration.zero;
  bool _isTimerActive = false;
  int _selectedPresetIndex = 1; // 15 min default

  late AnimationController _pulseController;

  final List<Duration> _presets = [
    const Duration(minutes: 5),
    const Duration(minutes: 15),
    const Duration(minutes: 30),
    const Duration(minutes: 45),
    const Duration(hours: 1),
  ];

  late final VoidCallback _serviceIsActiveListener;
  late final VoidCallback _serviceRemainingListener;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _serviceIsActiveListener = () {
      setState(() {
        _isTimerActive = SleepTimerService.instance.isActive.value;
      });
    };
    _serviceRemainingListener = () {
      setState(() {
        _remainingDuration = SleepTimerService.instance.remaining.value;
      });
    };

    SleepTimerService.instance.isActive.addListener(_serviceIsActiveListener);
    SleepTimerService.instance.remaining.addListener(_serviceRemainingListener);

    _isTimerActive = SleepTimerService.instance.isActive.value;
    _remainingDuration = SleepTimerService.instance.remaining.value;
  }

  @override
  void dispose() {
    SleepTimerService.instance.isActive.removeListener(_serviceIsActiveListener);
    SleepTimerService.instance.remaining.removeListener(_serviceRemainingListener);
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() => SleepTimerService.instance.start(_selectedDuration);
  void _stopTimer() => SleepTimerService.instance.stop();

  void _selectPreset(int index) {
    if (!_isTimerActive) {
      setState(() {
        _selectedPresetIndex = index;
        _selectedDuration = _presets[index];
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPreset(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final backgroundColor = isDark ? const Color(0xFF000000) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;

    final progress = _isTimerActive && _selectedDuration.inSeconds > 0
        ? 1 - (_remainingDuration.inSeconds / _selectedDuration.inSeconds)
        : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    onPressed: () => Navigator.pop(context),
                    child: Icon(
                      CupertinoIcons.back,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Timer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    children: [
                      // Circular Timer Display
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background circle
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                              ),
                            ),
                            // Progress circle
                            if (_isTimerActive)
                              CustomPaint(
                                size: const Size(280, 280),
                                painter: CircularProgressPainter(
                                  progress: progress,
                                  color: primaryColor,
                                ),
                              ),
                            // Center content
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _isTimerActive
                                          ? 0.4 + (_pulseController.value * 0.3)
                                          : 0.6,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    CupertinoIcons.moon_fill,
                                    size: 48,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  _isTimerActive
                                      ? _formatDuration(_remainingDuration)
                                      : _formatDuration(_selectedDuration),
                                  style: TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.w300,
                                    color: textColor,
                                    letterSpacing: -2,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isTimerActive ? 'remaining' : 'duration',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: subTextColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Quick Presets
                      if (!_isTimerActive) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: List.generate(_presets.length, (index) {
                              final isSelected = _selectedPresetIndex == index;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: index == 0 ? 0 : 4,
                                    right: index == _presets.length - 1 ? 0 : 4,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _selectPreset(index),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOut,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? primaryColor
                                            : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _formatPreset(_presets[index]),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected ? Colors.white : textColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Custom Time Picker
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 8),
                                child: Text(
                                  'Custom',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: subTextColor,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 180,
                                child: CupertinoTheme(
                                  data: CupertinoThemeData(
                                    brightness: isDark ? Brightness.dark : Brightness.light,
                                    primaryColor: primaryColor,
                                  ),
                                  child: CupertinoTimerPicker(
                                    mode: CupertinoTimerPickerMode.hms,
                                    initialTimerDuration: _selectedDuration,
                                    minuteInterval: 1,
                                    secondInterval: 1,
                                    onTimerDurationChanged: (duration) {
                                      setState(() {
                                        _selectedDuration = duration;
                                        _selectedPresetIndex = -1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Action Button
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _isTimerActive ? _stopTimer : _startTimer,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isTimerActive
                                ? const Color(0xFFFF453A)
                                : const Color(0xFFFF9F0A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isTimerActive
                                    ? CupertinoIcons.stop_fill
                                    : CupertinoIcons.play_fill,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isTimerActive ? 'Cancel' : 'Start',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_isTimerActive) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Music will pause when timer ends',
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ],
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

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
