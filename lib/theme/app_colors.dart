import 'package:flutter/material.dart';

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
