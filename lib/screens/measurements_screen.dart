// lib/screens/measurements_screen.dart (Final & De-Materialisiert - mit AppBar)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/measurement.dart';
import 'package:lightweight/models/measurement_session.dart';
import 'package:lightweight/screens/add_measurement_screen.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
import 'package:lightweight/widgets/summary_card.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  bool _isLoading = true;
  List<MeasurementSession> _sessions = [];
  String? _selectedChartType;
  List<String> _availableMeasurementTypes = [];

  DateTimeRange _currentChartDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );
  List<String> _chartDateRangeKeys = ['30D', '90D', '180D', 'All'];
  String _selectedChartRangeKey = '30D';

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  Future<void> _loadMeasurements() async {
    setState(() => _isLoading = true);
    final sessions = await DatabaseHelper.instance.getMeasurementSessions();

    final Set<String> types = {};
    for (final session in sessions) {
      for (final measurement in session.measurements) {
        types.add(measurement.type);
      }
    }

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _availableMeasurementTypes = types.toList()..sort();
        if (_selectedChartType == null &&
            _availableMeasurementTypes.isNotEmpty) {
          _selectedChartType = _availableMeasurementTypes.first;
        }
        _isLoading = false;
      });
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    if (_selectedChartType == null || _selectedChartType!.isEmpty) return;

    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedChartRangeKey) {
      case '90D':
        start = now.subtract(const Duration(days: 89));
        break;
      case '180D':
        start = now.subtract(const Duration(days: 179));
        break;
      case 'All':
        final earliest =
            await DatabaseHelper.instance.getEarliestMeasurementDate();
        start = earliest ?? now;
        break;
      case '30D':
      default:
        start = now.subtract(const Duration(days: 29));
    }

    setState(() {
      _currentChartDateRange = DateTimeRange(start: start, end: end);
    });
  }

  Future<void> _deleteSession(int id) async {
    await DatabaseHelper.instance.deleteMeasurementSession(id);
    _loadMeasurements();
  }

  void _navigateToCreateMeasurement() {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => const AddMeasurementScreen()))
        .then((_) => _loadMeasurements());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          l10n.measurementsScreenTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState(l10n, context)
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (_availableMeasurementTypes.isNotEmpty) ...[
                      _buildChartSection(l10n, colorScheme,Theme.of(context).textTheme),
                      const SizedBox(height: 24),
                    ],
                    _buildSectionTitle(context, "Alle Messwerte"),
                    ..._sessions.map((session) =>
                        _buildMeasurementSessionCard(l10n, colorScheme, session))
                  ],
                ),
      floatingActionButton: GlassFab(
          onPressed: _navigateToCreateMeasurement,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
  Widget _buildEmptyState(AppLocalizations l10n, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.measurementsEmptyState,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreateMeasurement,
              icon: const Icon(Icons.add),
              label: Text(l10n.addMeasurement),
            ),
          ],
        ),
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

  Widget _buildChartSection(
      AppLocalizations l10n, ColorScheme colorScheme, TextTheme textTheme) {
    if (_selectedChartType == null) return const SizedBox.shrink();

    return SummaryCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedChartType,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedChartType = newValue;
                          });
                          _loadChartData();
                        }
                      },
                      items: _availableMeasurementTypes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child:
                              Text(_getLocalizedMeasurementType(l10n, value)),
                        );
                      }).toList(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      icon: Icon(Icons.arrow_drop_down,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _chartDateRangeKeys
                      .map((key) => _buildFilterButton(key, key))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MeasurementChartWidget(
              chartType: _selectedChartType!,
              dateRange: _currentChartDateRange,
              lineColor: colorScheme.primary,
              unit: _getMeasurementUnit(_selectedChartType!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String key) {
    final theme = Theme.of(context);
    final isSelected = _selectedChartRangeKey == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartRangeKey = key;
        });
        _loadChartData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementSessionCard(AppLocalizations l10n,
      ColorScheme colorScheme, MeasurementSession session) {
    final locale = Localizations.localeOf(context).toString();
    final sortedMeasurements = session.measurements.toList()
      ..sort((a, b) => a.type.compareTo(b.type));

    return Dismissible(
      key: Key('session_${session.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteSession(session.id!),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: SummaryCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              title: Text(
                  DateFormat.yMMMMEEEEd(locale)
                      .add_Hm()
                      .format(session.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Detailansicht der Messsession.")),
                );
              },
            ),
            Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
            ...sortedMeasurements
                .map((measurement) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      leading: _getMeasurementIcon(measurement.type),
                      title: Text(_getLocalizedMeasurementType(
                          l10n, measurement.type)), // l10n übergeben
                      trailing: Text(
                          "${measurement.value.toStringAsFixed(1)} ${measurement.unit}",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  // HINZUGEFÜGT: Helfermethoden für Lokalisierung, Einheit und Icons
  String _getLocalizedMeasurementType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'weight':
        return l10n.measurementWeight;
      case 'fat_percent':
        return l10n.measurementFatPercent;
      case 'neck':
        return l10n.measurementNeck;
      case 'shoulder':
        return l10n.measurementShoulder;
      case 'chest':
        return l10n.measurementChest;
      case 'left_bicep':
        return l10n.measurementLeftBicep;
      case 'right_bicep':
        return l10n.measurementRightBicep;
      case 'left_forearm':
        return l10n.measurementLeftForearm;
      case 'right_forearm':
        return l10n.measurementRightForearm;
      case 'abdomen':
        return l10n.measurementAbdomen;
      case 'waist':
        return l10n.measurementWaist;
      case 'hips':
        return l10n.measurementHips;
      case 'left_thigh':
        return l10n.measurementLeftThigh;
      case 'right_thigh':
        return l10n.measurementRightThigh;
      case 'left_calf':
        return l10n.measurementLeftCalf;
      case 'right_calf':
        return l10n.measurementRightCalf;
      default:
        return type;
    }
  }

  String _getMeasurementUnit(String type) {
    // Hier die Einheiten basierend auf dem Typ zurückgeben
    switch (type) {
      case 'weight':
        return 'kg';
      case 'fat_percent':
        return '%';
      case 'neck':
      case 'shoulder':
      case 'chest':
      case 'left_bicep':
      case 'right_bicep':
      case 'left_forearm':
      case 'right_forearm':
      case 'abdomen':
      case 'waist':
      case 'hips':
      case 'left_thigh':
      case 'right_thigh':
      case 'left_calf':
      case 'right_calf':
        return 'cm';
      default:
        return '';
    }
  }

  Icon _getMeasurementIcon(String type) {
    // Hier Icons basierend auf dem Typ zurückgeben
    switch (type) {
      case 'weight':
        return const Icon(Icons.monitor_weight);
      case 'fat_percent':
        return const Icon(Icons.fitness_center);
      case 'neck':
        return const Icon(Icons.accessibility_new);
      case 'shoulder':
        return const Icon(Icons.accessibility_new);
      case 'chest':
        return const Icon(Icons.accessibility_new);
      case 'left_bicep':
        return const Icon(Icons.accessibility_new);
      case 'right_bicep':
        return const Icon(Icons.accessibility_new);
      case 'abdomen':
        return const Icon(Icons.accessibility_new);
      case 'waist':
        return const Icon(Icons.accessibility_new);
      case 'hips':
        return const Icon(Icons.accessibility_new);
      default:
        return const Icon(Icons.straighten);
    }
  }
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
