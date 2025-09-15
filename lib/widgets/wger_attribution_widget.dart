// lib/widgets/wger_attribution_widget.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lightweight/generated/app_localizations.dart';

class WgerAttributionWidget extends StatelessWidget {
  const WgerAttributionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          children: [
            TextSpan(text: '${l10n.exerciseDataAttribution} '),
            TextSpan(
              text: 'wger',
              style: TextStyle(
                color: colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(Uri.parse('https://wger.de'));
                },
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}