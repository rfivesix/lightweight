// lib/screens/profile_screen.dart (Der neue "Profil-Hub")

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/data_management_screen.dart';
import 'package:lightweight/screens/goals_screen.dart'; // HINZUGEFÜGT: Import für den neuen GoalsScreen
import 'package:lightweight/widgets/summary_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lightweight/services/profile_service.dart'; // HINZUGEFÜGT
import 'package:image_picker/image_picker.dart'; // HINZUGEFÜGT
import 'dart:io';

import 'package:provider/provider.dart'; // HINZUGEFÜGT

class ProfileScreen extends StatefulWidget {
  // KORREKTUR: Ist jetzt StatefulWidget
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // KORREKTUR: State-Klasse
  String _appVersion = "Lade..."; // Wird dynamisch geladen

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = "${packageInfo.version} (${packageInfo.buildNumber})";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = Provider.of<ProfileService>(context); // HINZUGEFÜGT

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // HINZUGEFÜGT: Profilbild-Sektion
          _buildSectionTitle(context, "PROFIL"),
          SummaryCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await profileService.pickAndSaveProfileImage();
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      backgroundImage: profileService.profileImagePath != null
                          ? FileImage(File(profileService.profileImagePath!))
                          : null,
                      child: profileService.profileImagePath == null
                          ? Icon(Icons.camera_alt,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  ),
                  if (profileService.profileImagePath != null)
                    TextButton(
                      onPressed: () async {
                        await profileService.deleteProfileImage();
                      },
                      child: const Text("Profilbild löschen"),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Sektion 1: "EINSTELLUNGEN"
          _buildSectionTitle(context, "EINSTELLUNGEN"),
          _buildNavigationCard(
            context: context,
            icon: Icons.flag_outlined,
            title: "Meine Ziele",
            subtitle: "Kalorien, Makros und Wasser anpassen.",
            onTap: () {
              // KORREKTUR: Navigation zum neuen GoalsScreen
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GoalsScreen()));
            },
          ),
          const SizedBox(height: 12),
          _buildNavigationCard(
            context: context,
            icon: Icons.import_export_rounded,
            title: "Datensicherung & Import",
            subtitle:
                "Backups erstellen, wiederherstellen und Daten importieren.",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DataManagementScreen()));
            },
          ),
          const SizedBox(height: 24),

          // Sektion 2: "ÜBER & RECHTLICHES"
          _buildSectionTitle(context, "ÜBER & RECHTLICHES"),
          _buildNavigationCard(
            context: context,
            icon: Icons.info_outline_rounded,
            title: "Attribution & Lizenzen",
            subtitle: "Daten von Open Food Facts und wger.",
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Attribution"),
                        content: const SingleChildScrollView(
                          child: Text(
                              "Diese App verwendet Daten von externen Quellen:\n\n"
                              "● Übungsdaten und Bilder von wger (wger.de), lizenziert unter der CC-BY-SA 4.0 Lizenz.\n\n"
                              "● Lebensmittel-Datenbank von Open Food Facts (openfoodfacts.org), verfügbar unter der Open Database License (ODbL)."),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("OK")),
                        ],
                      ));
            },
          ),
          const SizedBox(height: 12),
          SummaryCard(
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text("App-Version",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  _appVersion), // KORREKTUR: Zeigt die dynamische Version an
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildNavigationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SummaryCard(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        leading:
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      ),
    );
  }
}
