// lib/widgets/off_attribution_widget.dart

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class OffAttributionWidget extends StatelessWidget {
  final TextStyle? textStyle;

  const OffAttributionWidget({super.key, this.textStyle});

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
          // Macht den Text klickbar
          onTap: () async {
            final uri = Uri.parse("https://openfoodfacts.org/");
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                throw 'Could not launch $uri';
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(l10n.snackbar_could_not_open_open_link)),
                );
              }
            }
          },
          child: Text(
            l10n.openFoodFactsSource,
            style: currentTextStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
