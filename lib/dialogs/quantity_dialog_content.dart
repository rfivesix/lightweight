// lib/dialogs/quantity_dialog_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/generated/app_localizations.dart';
import 'package:lightweight/models/food_item.dart';

class QuantityDialogContent extends StatefulWidget {
  final FoodItem item;
  final int? initialQuantity;
  final DateTime? initialTimestamp;
  final String? initialMealType;

  const QuantityDialogContent({
    super.key,
    required this.item,
    this.initialQuantity,
    this.initialTimestamp,
    this.initialMealType,
  });

  @override
  QuantityDialogContentState createState() => QuantityDialogContentState();
}

class QuantityDialogContentState extends State<QuantityDialogContent> {
  late final TextEditingController _textController;
  late DateTime _selectedDateTime;
  bool _countAsWater = false;
  final List<String> _mealTypes = ["mealtypeBreakfast", "mealtypeLunch", "mealtypeDinner", "mealtypeSnack"];
  late String _selectedMealType;

  // Öffentliche Getter, damit von außen (über den GlobalKey) darauf zugegriffen werden kann
  String get quantityText => _textController.text;
  DateTime get selectedDateTime => _selectedDateTime;
  bool get countAsWater => _countAsWater;
  String get selectedMealType => _selectedMealType;
  
  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialQuantity?.toString() ?? '');
    _selectedDateTime = widget.initialTimestamp ?? DateTime.now();
    _selectedMealType = widget.initialMealType ?? "mealtypeSnack";
  }

  @override
  void dispose() { 
    _textController.dispose(); 
    super.dispose(); 
  }

  Future<void> _selectDate() async { 
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDateTime, firstDate: DateTime(2020), lastDate: DateTime.now()); 
    if (picked != null && picked != _selectedDateTime) { 
      setState(() { 
        _selectedDateTime = DateTime(picked.year, picked.month, picked.day, _selectedDateTime.hour, _selectedDateTime.minute); 
      }); 
    } 
  }

  Future<void> _selectTime() async { 
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime)); 
    if (picked != null) { 
      setState(() { 
        _selectedDateTime = DateTime(_selectedDateTime.year, _selectedDateTime.month, _selectedDateTime.day, picked.hour, picked.minute); 
      }); 
    } 
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);

    String getLocalizedMealName(String key) {
      switch (key) {
        case "mealtypeBreakfast": return l10n.mealtypeBreakfast;
        case "mealtypeLunch": return l10n.mealtypeLunch;
        case "mealtypeDinner": return l10n.mealtypeDinner;
        case "mealtypeSnack": return l10n.mealtypeSnack;
        default: return "Snack";
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(controller: _textController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Menge in Gramm", suffixText: 'g'), autofocus: true),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedMealType,
          decoration: const InputDecoration(labelText: 'Mahlzeit'),
          items: _mealTypes.map((String key) {
            return DropdownMenuItem<String>(
              value: key,
              child: Text(getLocalizedMealName(key)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMealType = newValue;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(onTap: _selectDate, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [const Icon(Icons.calendar_today, size: 20), const SizedBox(width: 8), Text(formattedDate, style: const TextStyle(fontSize: 16))]))),
          InkWell(onTap: _selectTime, child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [const Icon(Icons.access_time, size: 20), const SizedBox(width: 8), Text(formattedTime, style: const TextStyle(fontSize: 16))]))),
        ]),
        const SizedBox(height: 8),
        CheckboxListTile(title: const Text("Zur Trinkmenge hinzufügen"), value: _countAsWater, onChanged: (bool? newValue) { setState(() { _countAsWater = newValue ?? false; }); }, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
      ],
    );
  }
}
