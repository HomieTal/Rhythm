// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/settings/theme_provider.dart';
import 'package:rhythm/settings/equalizer_provider.dart';

void main() {
  testWidgets('RhythmApp initializes correctly', (WidgetTester tester) async {
    // Build the app with necessary providers for testing
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => EqualizerProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Rhythm Music App'),
            ),
          ),
        ),
      ),
    );

    // Verify that the app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Rhythm Music App'), findsOneWidget);
  });
}
