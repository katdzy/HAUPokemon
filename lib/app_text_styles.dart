import 'package:flutter/material.dart';

/// Responsive sizing helper.
///
/// [scale] computes a size relative to a 375-wide baseline screen.
/// The result is clamped so it never goes too small (0.8×) or too large (1.3×).
///
/// Usage:
///   fontSize: AppTextStyles.scale(context, 32)
///   size:     AppTextStyles.scale(context, 90)
class AppTextStyles {
  AppTextStyles._();

  static double scale(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    // Allow more shrinking (down to 0.5x), but keep the 1.3x max
    final factor = (width / 375).clamp(0.5, 1.3);
    
    final scaledSize = size * factor;
    // Enforce a hard floor of 10px for readability
    return scaledSize < 10.0 ? 10.0 : scaledSize;
  }
}
