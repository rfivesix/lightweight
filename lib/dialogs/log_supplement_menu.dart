import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/dialogs/log_supplement_dialog_content.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/models/supplement_log.dart';

class LogSupplementMenu extends StatefulWidget {
  const LogSupplementMenu({super.key, required this.close});

  final VoidCallback close;

  @override
  State<LogSupplementMenu> createState() => _LogSupplementMenuState();
}

class _LogSupplementMenuState extends State<LogSupplementMenu> {
  Supplement? _selected;
  List<Supplement> _supplements = [];
  final _doseKey = GlobalKey<LogSupplementDialogContentState>();

  @override
  void initState() {
    super.initState();
    _loadSupplements();
  }

  Future<void> _loadSupplements() async {
    final supplements = await DatabaseHelper.instance.getAllSupplements();
    if (mounted) {
      setState(() {
        _supplements = supplements;
      });
    }
  }

  String localizeSupplementName(Supplement s, AppLocalizations l10n) {
    switch (s.code) {
      case 'caffeine':
        return l10n.supplement_caffeine;
      case 'creatine_monohydrate':
        return l10n.supplement_creatine_monohydrate;
      default:
        return s.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_selected == null) {
      return _buildSupplementList(l10n);
    } else {
      return _buildDoseView(l10n);
    }
  }

  Widget _buildSupplementList(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._supplements.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Material(
                color: Colors.white.withOpacity(
                  Theme.of(context).brightness == Brightness.dark ? 0.06 : 0.08,
                ),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _selected = s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(localizeSupplementName(s, l10n))),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.close,
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDoseView(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            localizeSupplementName(_selected!, l10n),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        LogSupplementDialogContent(
          key: _doseKey,
          supplement: _selected!,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _selected = null),
                child: Text(l10n.onbBack),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  final st = _doseKey.currentState;
                  if (st == null) return;
                  final dose =
                      double.tryParse(st.doseText.replaceAll(',', '.'));
                  if (dose == null || dose <= 0) return;

                  final log = SupplementLog(
                    supplementId: _selected!.id!,
                    dose: dose,
                    unit: _selected!.unit,
                    timestamp: st.selectedDateTime,
                  );
                  await DatabaseHelper.instance.insertSupplementLog(log);
                  widget.close();
                  // This is a bit of a hack, but it's the easiest way to refresh the home screen
                  // without a more complex state management solution.
                  // Consider using a provider or riverpod to manage the state of the home screen.
                  // _refreshHomeScreen();
                },
                child: Text(l10n.add_button),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
