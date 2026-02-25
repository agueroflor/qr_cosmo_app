import 'package:flutter/material.dart';

/// Centralized spacing constants.
///
/// Replaces hardcoded EdgeInsets and SizedBox values across the app.
/// Based on a 4px grid system matching the existing codebase patterns.
abstract final class AppSpacing {
  // Raw values
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  // Symmetric padding helpers (most common patterns in codebase)
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);

  // Screen-level padding (horizontal 16-24, used in most screens)
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPaddingLg = EdgeInsets.all(lg);

  // Dialog padding (matches existing dialog patterns)
  static const EdgeInsets dialogContent = EdgeInsets.fromLTRB(xl, xl, xl, md);
  static const EdgeInsets dialogActions = EdgeInsets.fromLTRB(xl, sm, xl, lg);

  // Button internal padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(vertical: 14);

  // Vertical gaps (SizedBox replacements)
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);

  // Horizontal gaps
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
}
