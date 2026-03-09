import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

class PRDashboardScreen extends StatelessWidget {
  const PRDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prDashboardTitle)),
      body: Center(
        child: Text(l10n.prDashboardComingSoon),
      ),
    );
  }
}
