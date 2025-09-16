// lib/screens/data_management_screen.dart (Final & Vollständig)

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lightweight/data/backup_manager.dart';
import 'package:lightweight/data/import_manager.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/widgets/summary_card.dart';

class DataManagementScreen extends StatefulWidget {
  const DataManagementScreen({super.key});

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  // Lade-Zustände für die verschiedenen Aktionen
  bool _isFullBackupRunning = false;
  bool _isCsvExportRunning = false;
  bool _isMigrationRunning = false;

  // --- UNVERÄNDERT: Logik für Komplett-Backup ---
  void _performFullExport() async {
    setState(() => _isFullBackupRunning = true);
    final success = await BackupManager().exportFullBackup();
    if (!mounted) return;
    setState(() => _isFullBackupRunning = false);

    final l10n = AppLocalizations.of(context)!;
    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.snackbarExportSuccess)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.snackbarExportFailed),
          backgroundColor: Colors.orange));
    }
  }

  void _performFullImport() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final l10n = AppLocalizations.of(context)!;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogConfirmTitle),
        content: Text(l10n.dialogConfirmImportContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.dialogButtonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.dialogButtonOverwrite),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isFullBackupRunning = true);
      final success = await BackupManager().importFullBackup(filePath);
      if (!mounted) return;
      setState(() => _isFullBackupRunning = false);

      if (success) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.snackbarImportSuccessTitle),
            content: Text(l10n.snackbarImportSuccessContent),
            actions: [
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.snackbarButtonOK))
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.snackbarImportError),
            backgroundColor: Colors.red));
      }
    }
  }

  // --- UNVERÄNDERT: Logik für Hevy-Import ---
  void _performHevyImport() async {
    setState(() => _isMigrationRunning = true);
    final count = await ImportManager().importHevyCsv();
    if (!mounted) return;
    setState(() => _isMigrationRunning = false);

    final l10n = AppLocalizations.of(context)!;
    if (count > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.hevyImportSuccess(count))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.hevyImportFailed), backgroundColor: Colors.red));
    }
  }

  // --- NEU: Helfer-Methode für alle CSV-Exporte ---
  void _exportCsv(Future<bool> Function() exportFunction, String successMessage,
      String failureMessage) async {
    setState(() => _isCsvExportRunning = true);
    final success = await exportFunction();
    if (!mounted) return;
    setState(() => _isCsvExportRunning = false);

    if (success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMessage)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failureMessage), backgroundColor: Colors.orange));
    }
  }

@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  return Scaffold(
  appBar: AppBar(
    automaticallyImplyLeading: true, // <- zeigt den Zurück-Pfeil
    elevation: 0,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    scrolledUnderElevation: 0,
    centerTitle: false,
    title: Text(
      "Data Hub",
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    ),
  ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- bestehender Inhalt bleibt unverändert ---
            _buildFullBackupCard(context, l10n, theme),
            const SizedBox(height: 16),
            _buildCsvExportCard(context, l10n, theme),
            const SizedBox(height: 16),
            _buildMigrationCard(context, l10n, theme),
          ],
        ),
      ),
    ),
  );
}
  // --- WIDGET BUILDER ---

  Widget _buildFullBackupCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lightweight Datensicherung",
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
                "Sichere oder wiederherstelle alle deine App-Daten. Ideal für einen Gerätewechsel.",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.data_export_button),
                    onPressed: _isFullBackupRunning ? null : _performFullExport,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.download_for_offline),
                    label: Text(l10n.data_import_button),
                    style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error),
                    onPressed: _isFullBackupRunning ? null : _performFullImport,
                  ),
                ),
              ],
            ),
            if (_isFullBackupRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvExportCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daten-Export (CSV)", style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
                "Exportiere Teile deiner Daten als CSV-Datei zur Analyse in anderen Programmen.",
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            _buildExportTile(
              icon: Icons.restaurant_menu,
              title: "Ernährungstagebuch",
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                      BackupManager().exportNutritionAsCsv,
                      "Ernährungstagebuch wird geteilt...",
                      "Export fehlgeschlagen. Eventuell existieren noch keine Einträge."),
            ),
            _buildExportTile(
              icon: Icons.monitor_weight_outlined,
              title: "Messwerte",
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                      BackupManager().exportMeasurementsAsCsv,
                      "Messwerte werden geteilt...",
                      "Export fehlgeschlagen. Eventuell existieren noch keine Einträge."),
            ),
            _buildExportTile(
              icon: Icons.fitness_center,
              title: "Trainingsverlauf",
              onTap: _isCsvExportRunning
                  ? null
                  : () => _exportCsv(
                      BackupManager().exportWorkoutsAsCsv,
                      "Trainingsverlauf wird geteilt...",
                      "Export fehlgeschlagen. Eventuell existieren noch keine Einträge."),
            ),
            if (_isCsvExportRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationCard(
      BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hevyImportTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.hevyImportDescription, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync_alt),
                label: Text(l10n.hevyImportButton),
                onPressed: _isMigrationRunning ? null : _performHevyImport,
              ),
            ),
            if (_isMigrationRunning)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTile(
      {required IconData icon,
      required String title,
      required VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
