// lib/dialogs/water_dialog_content.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lightweight/generated/app_localizations.dart';

class WaterDialogContent extends StatefulWidget {
  const WaterDialogContent({super.key});
  @override
  WaterDialogContentState createState() => WaterDialogContentState();
}

class WaterDialogContentState extends State<WaterDialogContent> {
  late final TextEditingController _textController;
  late DateTime _selectedDateTime;
  late final l10n = AppLocalizations.of(context)!;

  String get quantityText => _textController.text;
  DateTime get selectedDateTime => _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _selectedDateTime = DateTime.now();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDateTime,
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(picked.year, picked.month, picked.day,
            _selectedDateTime.hour, _selectedDateTime.minute);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
            _selectedDateTime.year,
            _selectedDateTime.month,
            _selectedDateTime.day,
            picked.hour,
            picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(_selectedDateTime);
    final formattedTime = DateFormat.Hm().format(_selectedDateTime);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
            controller: _textController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: l10n.amount_in_milliliters, suffixText: 'ml'),
            autofocus: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
                onTap: _selectDate,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(formattedDate, style: const TextStyle(fontSize: 16))
                    ]))),
            InkWell(
                onTap: _selectTime,
                child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(formattedTime, style: const TextStyle(fontSize: 16))
                    ]))),
          ],
        ),
      ],
    );
  }
}
