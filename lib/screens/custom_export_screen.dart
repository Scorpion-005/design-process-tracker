import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';
import '../services/export_service.dart';

class CustomExportScreen extends StatefulWidget {
  final List<Design> designs;
  const CustomExportScreen({super.key, required this.designs});

  @override
  State<CustomExportScreen> createState() => _CustomExportScreenState();
}

class _CustomExportScreenState extends State<CustomExportScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  static const _allFields = [
    'RP No',
    'Design Name',
    'Company Name',
    'Customer Name',
    'Received Date',
    'CAD Approved Date',
    'CAD Approved By',
    'Strike Off Date',
    'Strike Off By',
    'Rotary Screen Date',
    'Rotary Screen By',
    'Current Stage',
  ];

  final Set<String> _selected = {
    'RP No',
    'Design Name',
    'Received Date',
    'Current Stage',
  };

  bool _exporting = false;

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = (isFrom ? _fromDate : _toDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _export() async {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one field')),
      );
      return;
    }
    setState(() => _exporting = true);
    // Keep the original field order regardless of tap order.
    final orderedFields =
        _allFields.where((f) => _selected.contains(f)).toList();
    await ExportService.exportCustomAndShare(
      widget.designs,
      fromDate: _fromDate,
      toDate: _toDate,
      fields: orderedFields,
    );
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Customized Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Date range (by received date)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: true),
                  child: Text(_fromDate != null
                      ? dateFmt.format(_fromDate!)
                      : 'From date'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(isFrom: false),
                  child: Text(
                      _toDate != null ? dateFmt.format(_toDate!) : 'To date'),
                ),
              ),
            ],
          ),
          if (_fromDate != null || _toDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    setState(() {
                  _fromDate = null;
                  _toDate = null;
                }),
                child: const Text('Clear dates (use all)'),
              ),
            ),
          const SizedBox(height: 20),
          Text('Fields to include',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          ..._allFields.map((field) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(field),
              value: _selected.contains(field),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selected.add(field);
                  } else {
                    _selected.remove(field);
                  }
                });
              },
            );
          }),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _exporting ? null : _export,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share),
            label: Text(_exporting ? 'Exporting...' : 'Export & Share'),
          ),
        ],
      ),
    );
  }
}
