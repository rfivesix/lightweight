// lib/widgets/wger_attribution_widget.dart

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class WgerAttributionWidget extends StatelessWidget {
  final TextStyle? textStyle;

  const WgerAttributionWidget({super.key, this.textStyle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentTextStyle = textStyle ??
        theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () async {
            final uri = Uri.parse("https://wger.de/");
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Konnte Link nicht öffnen")),
              );
            }
          },
          child: Text(
            l10n.exerciseDataAttribution,
            style: currentTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
