import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

class MuscleGroupAnalyticsScreen extends StatelessWidget {
  const MuscleGroupAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.muscleAnalyticsTitle)),
      body: Center(
        child: Text(l10n.muscleAnalyticsComingSoon),
      ),
    );
  }
}
