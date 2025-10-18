// lib/util/design_constants.dart
import 'package:flutter/material.dart';

class DesignConstants {
  // === SPACING ===
  // Card Padding
  static const double cardPaddingInternal = 16.0; // Innenabstand von Cards
  static const double cardPaddingExternal = 8.0; // Außenabstand zwischen Cards

  // General Spacing
  static const double spacingXS = 4.0; // Sehr kleine Abstände
  static const double spacingS = 8.0; // Kleine Abstände
  static const double spacingM = 12.0; // Mittlere Abstände
  static const double spacingL = 16.0; // Standard-Abstände
  static const double spacingXL = 24.0; // Große Abstände
  static const double spacingXXL = 32.0; // Sehr große Abstände
  static const double bottomContentSpacer = 80.0; // Platz für FAB etc.

  // Screen Padding
  static const double screenPaddingHorizontal = 16.0;
  static const double screenPaddingVertical = 8.0;

  // === BORDER RADIUS ===
  static const double borderRadiusS = 8.0; // Kleine Rundung
  static const double borderRadiusM = 12.0; // Standard Rundung
  static const double borderRadiusL = 16.0; // Große Rundung

  // === LIST SPACING ===
  static const double listItemSpacing = 8.0;
  static const double listSectionSpacing = 24.0;

  // === BUTTON SPACING ===
  static const double buttonPadding = 16.0;
  static const double buttonSpacing = 12.0;

  // === ICON SIZES ===
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;

  // === EDGE INSETS SHORTCUTS ===
  static const EdgeInsets cardPadding = EdgeInsets.all(cardPaddingInternal);
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    vertical: cardPaddingExternal,
  );
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
    vertical: screenPaddingVertical,
  );
  static const EdgeInsets listPadding = EdgeInsets.all(spacingL);
  static const EdgeInsets buttonContentPadding = EdgeInsets.symmetric(
    horizontal: buttonPadding,
    vertical: spacingM,
  );
}
