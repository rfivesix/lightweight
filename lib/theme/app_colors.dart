import 'package:flutter/material.dart';

/// Custom theme extension for application-specific surface colors.
///
/// Use this to define colors that aren't natively supported by the standard
/// [ThemeData], such as specific card backgrounds for summaries.
@immutable
class AppSurfaces extends ThemeExtension<AppSurfaces> {
  final Color summaryCard;
  const AppSurfaces({required this.summaryCard});

  @override
  AppSurfaces copyWith({Color? summaryCard}) =>
      AppSurfaces(summaryCard: summaryCard ?? this.summaryCard);

  @override
  AppSurfaces lerp(ThemeExtension<AppSurfaces>? other, double t) {
    if (other is! AppSurfaces) return this;
    return AppSurfaces(
      summaryCard: Color.lerp(summaryCard, other.summaryCard, t)!,
    );
  }
}
