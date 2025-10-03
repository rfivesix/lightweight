// lib/screens/manage_supplements_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/screens/create_supplement_screen.dart';
import 'package:lightweight/util/design_constants.dart';
import 'package:lightweight/util/supplement_l10n.dart';
import 'package:lightweight/widgets/glass_fab.dart';
import 'package:lightweight/widgets/summary_card.dart';
import 'package:lightweight/widgets/swipe_action_background.dart';

class ManageSupplementsScreen extends StatefulWidget {
  const ManageSupplementsScreen({super.key});

  @override
  State<ManageSupplementsScreen> createState() =>
      _ManageSupplementsScreenState();
}

class _ManageSupplementsScreenState extends State<ManageSupplementsScreen> {
  bool _isLoading = true;
  List<Supplement> _supplements = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getAllSupplements();
    if (!mounted) return;
    setState(() {
      _supplements = list;
      _isLoading = false;
    });
  }

  Future<void> _navigateToEdit(Supplement s) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => CreateSupplementScreen(supplementToEdit: s)),
    );
    if (changed == true) _load();
  }

  Future<void> _delete(Supplement s) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l10n.deleteConfirmTitle),
              content: Text(
                l10n.deleteConfirmContent, // du kannst hier einen spezifischen Text ergänzen
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.cancel)),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(l10n.delete)),
              ],
            ),
          ) ??
          false;
      if (!ok) return;

      await DatabaseHelper.instance.deleteSupplement(s.id!);
      if (!mounted) return;
      _load();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleted)));
    } catch (e) {
      // builtin blockiert -> freundlich erklären
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                l10n.operationNotAllowed /* ergänze passenden l10n-Text */)),
      );
    }
  }

  Widget _tile(Supplement s, AppLocalizations l10n) {
    final isBuiltin = s.isBuiltin || s.code == 'caffeine';
    final title = localizeSupplementName(s, l10n);

    final content = SummaryCard(
      child: ListTile(
        leading: const Icon(Icons.set_meal_outlined),
        title: Text(title),
        subtitle: (s.dailyGoal != null || s.dailyLimit != null)
            ? Text([
                if (s.dailyGoal != null)
                  '${l10n.dailyGoalLabel}: ${s.dailyGoal} ${s.unit}',
                if (s.dailyLimit != null)
                  '${l10n.dailyLimitLabel}: ${s.dailyLimit} ${s.unit}',
              ].join('  •  '))
            : null,
        trailing: isBuiltin ? null : const Icon(Icons.chevron_right),
        onTap: () => _navigateToEdit(s),
      ),
    );

    if (isBuiltin) return content;

    return Dismissible(
      key: Key('supp_${s.id}'),
      direction: DismissDirection.horizontal,
      background: const SwipeActionBackground(
        color: Colors.blueAccent,
        icon: Icons.edit,
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const SwipeActionBackground(
        color: Colors.redAccent,
        icon: Icons.delete,
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _navigateToEdit(s);
          return false;
        } else {
          _delete(s);
          return false;
        }
      },
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.manageSupplementsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: DesignConstants.cardPadding,
                children: [
                  if (_supplements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(l10n.emptySupplements,
                          textAlign: TextAlign.center),
                    )
                  else
                    ..._supplements.map((s) => _tile(s, l10n)),
                ],
              ),
            ),
      floatingActionButton: GlassFab(
        label: l10n.createSupplementTitle,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
                builder: (context) => const CreateSupplementScreen()),
          );
          if (created == true) _load();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
