// lib/widgets/off_attribution_widget.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OffAttributionWidget extends StatelessWidget {
  const OffAttributionWidget({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konnte den Link nicht öffnen: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: InkWell(
          onTap: () => _launchURL('https://world.openfoodfacts.org', context),
          child: Text(
            "(c) Open Food Facts contributors",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),
      ),
    );
  }
}