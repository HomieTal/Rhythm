import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm/screens/language_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  double _swipeProgress = 0.0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSwipeUpdate(DragUpdateDetails details, double maxWidth) {
    if (_isCompleted) return;

    setState(() {
      _swipeProgress += details.delta.dx / maxWidth;
      _swipeProgress = _swipeProgress.clamp(0.0, 1.0);
    });

    if (_swipeProgress >= 0.95) {
      _completeSwipe();
    }
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (_isCompleted) return;

    if (_swipeProgress < 0.95) {
      setState(() {
        _swipeProgress = 0.0;
      });
    }
  }

  void _completeSwipe() {
    if (_isCompleted) return;

    setState(() {
      _isCompleted = true;
      _swipeProgress = 1.0;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateToHome();
    });
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LanguageSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00A896),
              Color(0xFF028A7C),
              Color(0xFF027368),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Stack(
                children: [
                  // Background Image with Opacity
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        'assets/images/welcome.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/developer.jpg',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),

                  // Gradient overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha((0.3 * 255).round()),
                            Colors.black.withAlpha((0.6 * 255).round()),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Bottom content (text in front)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 50),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title - Left aligned
                          const Text(
                            'Feel the Music',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Live the ',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Moment',
                                  style: TextStyle(
                                    color: Color(0xFFFF2D55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description - Left aligned
                          Text(
                            'Enjoy effortless music, perfectly tuned\nfor every moment.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withAlpha((0.9 * 255).round()),
                              height: 1.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Swipe Button
                          _buildSwipeButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final buttonWidth = constraints.maxWidth;
        final iconSize = 64.0;
        final maxSwipeDistance = buttonWidth - iconSize - 8;

        return Container(
          width: double.infinity,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha((0.95 * 255).round()),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.2 * 255).round()),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Progress background
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _swipeProgress * buttonWidth,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D55),
                      Color(0xFFFF6B8A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(36),
                ),
              ),

              // Text label
              Center(
                child: Text(
                  _swipeProgress > 0.5 ? 'Release to start!' : 'Swipe to start exploring',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _swipeProgress > 0.3
                        ? Colors.white
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),

              // Swipeable icon
              AnimatedPositioned(
                duration: const Duration(milliseconds: 50),
                left: 4 + (_swipeProgress * maxSwipeDistance),
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    _handleSwipeUpdate(details, buttonWidth);
                  },
                  onHorizontalDragEnd: _handleSwipeEnd,
                  onTap: () {
                    // Fallback: also allow tap to navigate
                    _completeSwipe();
                  },
                  child: Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF2D55),
                          Color(0xFFFF6B8A),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF2D55).withAlpha((0.5 * 255).round()),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted
                          ? Icons.check_rounded
                          : Icons.keyboard_double_arrow_right_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

