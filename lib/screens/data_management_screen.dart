// lib/screens/data_management_screen.dart

import 'package:flutter/material.dart';
import 'package:lightweight/data/backup_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/data/import_manager.dart';
  

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  bool _isExporting = false;
  bool _isImporting = false;


  void _exportData() async {
    setState(() => _isExporting = true);
    
    final manager = BackupManager();
    final success = await manager.exportData();
    final l10n = AppLocalizations.of(context)!;

    if (!mounted) return;

    setState(() => _isExporting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarExportSuccess),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      // Wenn 'success' false ist, kann es ein Fehler sein oder der Nutzer hat abgebrochen.
      // Eine stille Rückkehr ist hier oft die beste User Experience.
      // Optional kann man eine Meldung für den Fehlerfall anzeigen.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.snackbarExportFailed),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _importData() async {
    // 1. Dateiauswahl-Dialog öffnen
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final l10n = AppLocalizations.of(context)!;

    if (result == null || result.files.single.path == null) {
      // Nutzer hat den Dialog abgebrochen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.snackbarNoFileSelected)));
      return;
    }
    
    final filePath = result.files.single.path!;

    // 2. Warn-Dialog anzeigen
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogConfirmTitle),
        content: Text(l10n.dialogConfirmImportContent),
        actions: [
          TextButton(child: Text(l10n.dialogButtonCancel),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            //child: const Text("Ja, alles überschreiben"),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.dialogButtonOverwrite)
          ),
        ],
      ),
    );

    // 3. Wenn der Nutzer bestätigt hat, den Import starten
    if (confirmed == true) {
      setState(() => _isImporting = true);
      
      final manager = BackupManager();
      final success = await manager.importData(filePath);

      if (!mounted) return;

      setState(() => _isImporting = false);

      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false, // Nutzer muss den Dialog bestätigen
          builder: (context) => AlertDialog(
            title: Text(l10n.snackbarImportSuccessTitle),
            content: Text(l10n.snackbarImportSuccessContent),
            actions: [ FilledButton(child: Text(l10n.snackbarButtonOK),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.snackbarImportError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

void _importHevyData() async {
    setState(() => _isImporting = true);
    final count = await ImportManager().importHevyCsv();
    if (!mounted) return;
    setState(() => _isImporting = false);

    final l10n = AppLocalizations.of(context)!;
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hevyImportSuccess(count))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.hevyImportFailed), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dataManagementTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      // DOC: HIER IST DIE KORREKTUR
      // Wir wickeln den Body in einen SingleChildScrollView
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                context: context,
                icon: Icons.upload_file,
                title: l10n.exportCardTitle,
                description: l10n.exportCardDescription,
                buttonText: l10n.exportCardButton,
                isLoading: _isExporting,
                onPressed: _exportData,
              ),
              const SizedBox(height: 24),
              _buildCard(
                context: context,
                icon: Icons.download_for_offline,
                title: l10n.importCardTitle,
                description: l10n.importCardDescription,
                buttonText: l10n.importCardButton,
                isLoading: _isImporting,
                onPressed: _importData,
                isDestructive: true,
              ),
              const SizedBox(height: 24),
              // Die neue Karte für den Hevy Import
              _buildCard(
                context: context,
                icon: Icons.sync_alt,
                title: l10n.hevyImportTitle,
                description: l10n.hevyImportDescription,
                buttonText: l10n.hevyImportButton,
                isLoading: _isImporting,
                onPressed: _importHevyData,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required bool isLoading,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = isDestructive ? colorScheme.error : colorScheme.primary;
    final onButtonColor = isDestructive ? colorScheme.onError : colorScheme.onPrimary;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: onButtonColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}