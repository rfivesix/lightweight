import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

class RecoveryTrackerScreen extends StatelessWidget {
  const RecoveryTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.recoveryTrackerTitle)),
      body: Center(
        child: Text(l10n.recoveryTrackerComingSoon),
      ),
    );
  }
}
