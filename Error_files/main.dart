import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:Rhythm/screen/splash_screen.dart';
import 'package:Rhythm/settings/theme_provider.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/service/cache_service.dart';
import 'package:Rhythm/service/recently_played_service.dart';
import 'package:Rhythm/service/search_history_service.dart';
import 'package:Rhythm/settings/equalizer_provider.dart';
// COMMENTED OUT - Auto coloring feature disabled
// import 'package:Rhythm/widgets/auto_coloring_listener.dart';

Future<void> main() async {
  // CRITICAL: Initialize Flutter bindings BEFORE everything else
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Set preferred orientations with error handling
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e) {
    debugPrint('Error setting orientation: $e');
  }

  // Initialize critical services before running app
  await _initializeServices();

  // Handle errors outside of Flutter framework
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => EqualizerProvider()),
        ],
        child: const _EqualizerSyncWidget(child: RhythmApp()),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stack');
  });
}

/// Initialize all services with graceful error handling
Future<void> _initializeServices() async {
  debugPrint('🚀 Starting services initialization...');

  // Initialize AudioController first (singleton pattern ensures single instance)
  try {
    final audioController = AudioController.instance;
    debugPrint('✅ AudioController instance created');
    // Don't load songs yet - let the UI handle it after permissions
  } catch (e) {
    debugPrint('⚠️ AudioController initialization failed: $e');
  }

  // Initialize cache service with timeout
  try {
    await CacheService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ CacheService initialization timed out');
      },
    );
    debugPrint('✅ CacheService initialized');
  } catch (e) {
    debugPrint('⚠️ CacheService initialization failed: $e');
  }

  // Initialize recently played service with timeout
  try {
    await RecentlyPlayedService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ RecentlyPlayedService initialization timed out');
      },
    );
    debugPrint('✅ RecentlyPlayedService initialized');
  } catch (e) {
    debugPrint('⚠️ RecentlyPlayedService initialization failed: $e');
  }

  // Initialize search history service with timeout
  try {
    await SearchHistoryService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ SearchHistoryService initialization timed out');
      },
    );
    debugPrint('✅ SearchHistoryService initialized');
  } catch (e) {
    debugPrint('⚠️ SearchHistoryService initialization failed: $e');
  }

  debugPrint('✅ All services initialization completed');
}

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Determine brightness based on theme settings with null safety
        Brightness brightness;
        try {
          if (themeProvider.useSystemTheme) {
            brightness = MediaQuery.platformBrightnessOf(context);
          } else {
            brightness = themeProvider.isDarkMode ? Brightness.dark : Brightness.light;
          }
        } catch (e) {
          debugPrint('Error determining brightness: $e');
          brightness = Brightness.light; // Default to light mode
        }

        final isDark = brightness == Brightness.dark;
        final primaryColor = themeProvider.dynamicColor;
        final backgroundColor = themeProvider.backgroundColor;

        // COMMENTED OUT - Auto coloring listener disabled
        // return AutoColoringListener(
        //   child: MaterialApp(
        return MaterialApp(
          title: 'Rhythm',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: brightness,
            scaffoldBackgroundColor: backgroundColor,
            primaryColor: primaryColor,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: brightness,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              centerTitle: true,
              iconTheme: IconThemeData(color: primaryColor),
              titleTextStyle: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            cardColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            iconTheme: IconThemeData(color: primaryColor),
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: isDark ? Colors.white : Colors.black87),
              bodyMedium: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
          home: const SplashScreen(),
        );
        // COMMENTED OUT - Auto coloring listener closing
        // ),
      },
    );
  }
}

// Listen to EqualizerProvider changes and apply them to the AudioController.
// We add a small root widget that consumes EqualizerProvider and calls the controller.
class _EqualizerSyncWidget extends StatefulWidget {
  final Widget child;
  const _EqualizerSyncWidget({required this.child, Key? key}) : super(key: key);

  @override
  State<_EqualizerSyncWidget> createState() => _EqualizerSyncWidgetState();
}

class _EqualizerSyncWidgetState extends State<_EqualizerSyncWidget> {
  EqualizerProvider? _last;

  void _onProviderChanged() {
    final provider = _last;
    if (provider == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioController.instance.applySettingsFromProvider(provider);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<EqualizerProvider>(context);
    if (_last != provider) {
      // remove old listener
      _last?.removeListener(_onProviderChanged);
      _last = provider;
      _last?.addListener(_onProviderChanged);
      // apply initial settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AudioController.instance.applySettingsFromProvider(provider);
      });
    }
  }

  @override
  void dispose() {
    _last?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
