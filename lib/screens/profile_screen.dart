import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/screens/goals_screen.dart';
import 'package:lightweight/screens/onboarding_screen.dart';
import 'package:lightweight/screens/settings_screen.dart';
import 'package:lightweight/services/profile_service.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profileService = Provider.of<ProfileService>(context);

    return Scaffold(
      body: ListView(
        padding: DesignConstants.cardPadding,
        children: [
          // Profilbild-Sektion
          _buildSectionTitle(l10n.profile_capslock),
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
                      key: ValueKey(
                          '${profileService.profileImagePath ?? ''}${profileService.cacheBuster}'),
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
                      child: Text(l10n.delete_profile_picture_button),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignConstants.spacingXL),

          // Sektion für Navigation
          // HINWEIS: Der redundante Titel "EINSTELLUNGEN" wurde entfernt.
          _buildNavigationCard(
            icon: Icons.settings_outlined,
            title: l10n.settingsTitle,
            subtitle:
                "Theme, units, data and more", // TODO: Localize this subtitle
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SettingsScreen()));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildNavigationCard(
            icon: Icons.flag_outlined,
            title: l10n.my_goals,
            subtitle: l10n.my_goals_description,
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const GoalsScreen()));
            },
          ),
          const SizedBox(height: DesignConstants.spacingM),
          _buildOnboardingCard(l10n),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
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

  Widget _buildOnboardingCard(AppLocalizations l10n) {
    // KORREKTUR: 'theme' wird direkt hier aus dem context geholt.
    final theme = Theme.of(context);

    return SummaryCard(
      child: ListTile(
        leading: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
        title: Text(
          l10n.onbShowTutorialAgain,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          l10n.onbFinishBody,
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
