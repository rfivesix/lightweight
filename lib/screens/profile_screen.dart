// lib/screens/profile_screen.dart (Der neue "Profil-Hub")

import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/data_management_screen.dart';
import 'package:lightweight/screens/goals_screen.dart'; // HINZUGEFÜGT: Import für den neuen GoalsScreen
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:lightweight/services/profile_service.dart'; // HINZUGEFÜGT
import 'package:lightweight/screens/onboarding_screen.dart';

// HINZUGEFÜGT
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
  late final l10n = AppLocalizations.of(context)!;
  late final theme = Theme.of(context);
  late String _appVersion = l10n.load_dots; // Wird dynamisch geladen

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
        padding: DesignConstants.cardPadding,
        children: [
          // HINZUGEFÜGT: Profilbild-Sektion
          _buildSectionTitle(context, l10n.profile_capslock),
          SummaryCard(
            child: Padding(
              padding: DesignConstants.cardPadding,
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
                      // Wir erstellen das backgroundImage jetzt so:
                      backgroundImage: profileService.profileImagePath != null
                          ? Image.file(
                              File(profileService.profileImagePath!),
                              // Dieser Key ist jetzt korrekt am Image-Widget
                              key: ValueKey(
                                  '${profileService.profileImagePath}${profileService.hashCode}'),
                            ).image // Wir greifen auf die .image Eigenschaft zu, die der CircleAvatar braucht
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
                      child: Text(l10n.delete_profile_picture_button),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),
          // Sektion 1: "EINSTELLUNGEN"
          _buildSectionTitle(context, l10n.settings_capslock),
          _buildNavigationCard(
            context: context,
            icon: Icons.flag_outlined,
            title: l10n.my_goals,
            subtitle: l10n.my_goals_description,
            onTap: () {
              // KORREKTUR: Navigation zum neuen GoalsScreen
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GoalsScreen()));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildNavigationCard(
            context: context,
            icon: Icons.import_export_rounded,
            title: l10n.backup_and_import,
            subtitle: l10n.backup_and_import_description,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const DataManagementScreen()));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildOnboardingCard(context, l10n, theme),
          const SizedBox(height: DesignConstants.spacingXL),

          // Sektion 2: "ÜBER & RECHTLICHES"
          _buildSectionTitle(context, l10n.about_and_legal_capslock),
          _buildNavigationCard(
            context: context,
            icon: Icons.info_outline_rounded,
            title: l10n.attribution_and_license,
            subtitle: l10n.data_from_off_and_wger,
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: Text(l10n.attribution_title),
                        content: SingleChildScrollView(
                          child: Text(l10n.attributionText),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(l10n.snackbar_button_ok)),
                        ],
                      ));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          SummaryCard(
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: Text(l10n.app_version,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildOnboardingCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
        title: Text(
          l10n.onbShowTutorialAgain,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.onbFinishBody, // kurzer Erklärungstext wiederverwendet
          style: theme.textTheme.bodyMedium,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        },
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
