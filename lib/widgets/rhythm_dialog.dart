import 'dart:ui';

import 'package:flutter/material.dart';

class RhythmDialog extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double outerBlur;
  final double innerBlur;
  final bool glassy;

  const RhythmDialog({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 24,
    this.outerBlur = 16,
    this.innerBlur = 12,
    this.glassy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: outerBlur, sigmaY: outerBlur),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Container(
          decoration: BoxDecoration(
            // Outer decoration: use gradient normally, but when glassy use transparent background
            gradient: glassy
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF1A1A2E), Color(0xFF16213E)]
                        : const [Color(0xFFF0F4F8), Color(0xFFE2E8F0)],
                  ),
            color: glassy ? Colors.transparent : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark
                  ? (glassy ? Colors.white.withAlpha((0.06 * 255).round()) : Colors.white.withAlpha((0.12 * 255).round()))
                  : (glassy ? Colors.black.withAlpha((0.06 * 255).round()) : Colors.black.withAlpha((0.08 * 255).round())),
            ),
            boxShadow: [
              BoxShadow(
                color: glassy
                    ? Colors.black.withAlpha((0.10 * 255).round())
                    : Colors.black.withAlpha((0.25 * 255).round()),
                blurRadius: glassy ? 12 : 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: innerBlur, sigmaY: innerBlur),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.black.withAlpha((0.40 * 255).round())
                          : Colors.white.withAlpha((0.88 * 255).round()),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showRhythmDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool glassy = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => RhythmDialog(glassy: glassy, child: builder(dialogContext)),
  );
}
