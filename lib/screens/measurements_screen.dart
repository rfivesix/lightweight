// lib/screens/measurements_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/measurement_session.dart';
import 'package:lightweight/models/measurement.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'add_measurement_screen.dart';
import 'package:lightweight/models/chart_data_point.dart';
import 'package:lightweight/widgets/measurement_chart_widget.dart';
// import 'measurement_session_detail_screen.dart'; // Auskommentiert, bis der Screen erstellt ist

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  bool _isLoading = true;
  List<MeasurementSession> _sessions = [];
  List<ChartDataPoint> _chartData = [];
  String _selectedChartType = 'weight';
  bool _isChartLoading = true;
  late DateTimeRange _currentDateRange;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 30));
    _currentDateRange = DateTimeRange(start: startDate, end: now);
    _loadAllData();
  }
  // NEUE State-Variable für die FilterChips
  String _selectedRangeKey = '1M';

  // NEUE Methode zum Setzen des Zeitraums
  void _setTimeRange(String key) async {
    setState(() => _selectedRangeKey = key);
    final now = DateTime.now();
    DateTime start;

    switch (key) {
      case '3M':
        start = now.subtract(const Duration(days: 90));
        break;
      case '1J':
        start = now.subtract(const Duration(days: 365));
        break;
      case 'Alle':
        final earliest = await DatabaseHelper.instance.getEarliestMeasurementDate();
        start = earliest ?? now.subtract(const Duration(days: 30));
        break;
      case '1M':
      default:
        start = now.subtract(const Duration(days: 30));
    }
    setState(() {
      _currentDateRange = DateTimeRange(start: start, end: now);
    });
    _loadChartData(_selectedChartType);
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadSessions();
    await _loadChartData(_selectedChartType);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSessions() async {
    final data = await DatabaseHelper.instance.getMeasurementSessions();
    if (mounted) setState(() => _sessions = data);
  }

  Future<void> _loadChartData(String type) async {
    setState(() => _isChartLoading = true);
    final data = await DatabaseHelper.instance.getChartDataForTypeAndRange(type, _currentDateRange);
    if (mounted) {
      setState(() {
        _chartData = data;
        _isChartLoading = false;
      });
    }
  }

  void _navigateTimeRange(bool forward) {
    final duration = _currentDateRange.duration;
    DateTime newStart;
    DateTime newEnd;

    if (forward) {
      newStart = _currentDateRange.start.add(duration);
      newEnd = _currentDateRange.end.add(duration);
      if (newEnd.isAfter(DateTime.now())) {
        newEnd = DateTime.now();
        newStart = newEnd.subtract(duration);
      }
    } else {
      newStart = _currentDateRange.start.subtract(duration);
      newEnd = _currentDateRange.end.subtract(duration);
    }

    setState(() => _currentDateRange = DateTimeRange(start: newStart, end: newEnd));
    _loadChartData(_selectedChartType);
  }

  void _navigateToAddScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddMeasurementScreen()),
    ).then((result) {
      if (result == true) _loadAllData();
    });
  }

  void _deleteSession(int id) async {
    await DatabaseHelper.instance.deleteMeasurementSession(id);
    _loadAllData();
  }

  String _getLocalizedMeasurementName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'weight': return l10n.measurementWeight;
      case 'fat_percent': return l10n.measurementFatPercent;
      case 'neck': return l10n.measurementNeck;
      case 'shoulder': return l10n.measurementShoulder;
      case 'chest': return l10n.measurementChest;
      case 'left_bicep': return l10n.measurementLeftBicep;
      case 'right_bicep': return l10n.measurementRightBicep;
      case 'left_forearm': return l10n.measurementLeftForearm;
      case 'right_forearm': return l10n.measurementRightForearm;
      case 'abdomen': return l10n.measurementAbdomen;
      case 'waist': return l10n.measurementWaist;
      case 'hips': return l10n.measurementHips;
      case 'left_thigh': return l10n.measurementLeftThigh;
      case 'right_thigh': return l10n.measurementRightThigh;
      case 'left_calf': return l10n.measurementLeftCalf;
      case 'right_calf': return l10n.measurementRightCalf;
      default: return key;
    }
  }

  String _getUnitForSelectedType() {
    if (_sessions.isEmpty) return '';
    for (final session in _sessions) {
      final measurement = session.measurements.firstWhere(
        (m) => m.type == _selectedChartType,
        orElse: () => Measurement(sessionId: 0, type: '', value: 0, unit: 'NOT_FOUND'),
      );
      if (measurement.unit != 'NOT_FOUND') return measurement.unit;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.measurementsScreenTitle),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SummaryCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildChartTypeSelector(l10n, colorScheme)),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _navigateTimeRange(false)),
                                Text(
                                  "${DateFormat.MMMd().format(_currentDateRange.start)} - ${DateFormat.MMMd().format(_currentDateRange.end)}",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _navigateTimeRange(true)),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            FilterChip(label: const Text("1M"), selected: _selectedRangeKey == '1M', onSelected: (_) => _setTimeRange('1M')),
                            FilterChip(label: const Text("3M"), selected: _selectedRangeKey == '3M', onSelected: (_) => _setTimeRange('3M')),
                            FilterChip(label: const Text("1J"), selected: _selectedRangeKey == '1J', onSelected: (_) => _setTimeRange('1J')),
                            FilterChip(label: const Text("Alle"), selected: _selectedRangeKey == 'Alle', onSelected: (_) => _setTimeRange('Alle')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onHorizontalDragEnd: (details) {
                            if (details.primaryVelocity! > 0) _navigateTimeRange(false);
                            if (details.primaryVelocity! < 0) _navigateTimeRange(true);
                          },
                          child: _isChartLoading
                              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                              : MeasurementChartWidget(
                                  //title: _getLocalizedMeasurementName(_selectedChartType, l10n),
                                  dataPoints: _chartData,
                                  lineColor: colorScheme.primary,
                                  unit: _getUnitForSelectedType(),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text("Verlaufsprotokoll", style: Theme.of(context).textTheme.headlineSmall),
                ),
                _sessions.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text(l10n.measurementsEmptyState, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey))))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final weightEntry = session.measurements.firstWhere((m) => m.type == 'weight', orElse: () => Measurement(sessionId: 0, type: '', value: 0, unit: ''));
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                child: Icon(Icons.calendar_today_outlined, color: colorScheme.onPrimaryContainer),
                              ),
                              title: Text(DateFormat.yMMMMd('de_DE').format(session.timestamp), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${session.measurements.length} Messwerte erfasst"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (weightEntry.value > 0)
                                    Text("${weightEntry.value.toStringAsFixed(1)} ${weightEntry.unit}", style: Theme.of(context).textTheme.titleMedium),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _deleteSession(session.id!),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Navigator.of(context).push(MaterialPageRoute(builder: (context) => MeasurementSessionDetailScreen(session: session)));
                              },
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChartTypeSelector(AppLocalizations l10n, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      onSelected: (String newValue) {
        setState(() => _selectedChartType = newValue);
        _loadChartData(newValue);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem(value: 'weight', child: Text(l10n.measurementWeight)),
        PopupMenuItem(value: 'fat_percent', child: Text(l10n.measurementFatPercent)),
        PopupMenuItem(value: 'waist', child: Text(l10n.measurementWaist)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _getLocalizedMeasurementName(_selectedChartType, l10n),
                style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}