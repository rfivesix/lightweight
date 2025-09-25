// lib/screens/create_supplement_screen.dart
import 'package:flutter/material.dart';
import 'package:lightweight/data/database_helper.dart';
import 'package:lightweight/models/supplement.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/util/design_constants.dart';

class CreateSupplementScreen extends StatefulWidget {
  const CreateSupplementScreen({super.key});
  @override
  State<CreateSupplementScreen> createState() => _CreateSupplementScreenState();
}

class _CreateSupplementScreenState extends State<CreateSupplementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _unitController = TextEditingController();
  final _goalController = TextEditingController();
  final _limitController = TextEditingController();
  final _notesController = TextEditingController();

  late final l10n = AppLocalizations.of(context)!;

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _unitController.dispose();
    _goalController.dispose();
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSupplement() async {
    if (_formKey.currentState!.validate()) {
      final newSupplement = Supplement(
        name: _nameController.text.trim(),
        defaultDose:
            double.tryParse(_doseController.text.replaceAll(',', '.')) ?? 0.0,
        unit: _unitController.text.trim(),
        dailyGoal: double.tryParse(_goalController.text.replaceAll(',', '.')),
        dailyLimit: double.tryParse(_limitController.text.replaceAll(',', '.')),
        notes: _notesController.text.trim(),
      );

      await DatabaseHelper.instance.insertSupplement(newSupplement);
      if (mounted) {
        Navigator.of(context)
            .pop(true); // Gib 'true' zurück, um Neuladen zu signalisieren
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createSupplementTitle),
        actions: [
          TextButton(
            onPressed: _saveSupplement,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignConstants.cardPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, l10n.supplementNameLabel,
                  isRequired: true),
              const SizedBox(height: DesignConstants.spacingL),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          _doseController, l10n.defaultDoseLabel,
                          isNumeric: true)),
                  const SizedBox(width: DesignConstants.spacingM),
                  Expanded(
                      child: _buildTextField(_unitController, l10n.unitLabel)),
                ],
              ),
              const SizedBox(height: DesignConstants.spacingXL),
              _buildTextField(_goalController, l10n.dailyGoalLabel,
                  isNumeric: true),
              const SizedBox(height: DesignConstants.spacingL),
              _buildTextField(_limitController, l10n.dailyLimitLabel,
                  isNumeric: true),
              const SizedBox(height: DesignConstants.spacingL),
              _buildTextField(_notesController, l10n.notesLabel, maxLines: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isRequired = false,
    bool isNumeric = false,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return l10n.validatorPleaseEnterName;
        }
        if (isNumeric &&
            value != null &&
            value.isNotEmpty &&
            double.tryParse(value.replaceAll(',', '.')) == null) {
          return l10n.validatorPleaseEnterNumber;
        }
        return null;
      },
    );
  }
}
