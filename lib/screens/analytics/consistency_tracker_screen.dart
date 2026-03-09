import 'package:flutter/material.dart';
import '../../generated/app_localizations.dart';

class ConsistencyTrackerScreen extends StatelessWidget {
  const ConsistencyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.consistencyTrackerTitle)),
      body: Center(
        child: Text(l10n.consistencyTrackerComingSoon),
      ),
    );
  }
}
