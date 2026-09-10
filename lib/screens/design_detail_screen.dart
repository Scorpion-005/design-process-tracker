import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';
import '../services/database_service.dart';

class DesignDetailScreen extends StatefulWidget {
  final Design design;
  const DesignDetailScreen({super.key, required this.design});

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  late Design _design;

  @override
  void initState() {
    super.initState();
    _design = widget.design;
  }

  Future<void> _pickAndSetDate(String field) async {
    final initial = _fieldDate(field) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      switch (field) {
        case 'cad':
          _design.cadApprovedDate = picked;
          break;
        case 'strike':
          _design.strikeOffDate = picked;
          break;
        case 'rotary':
          _design.rotaryScreenDate = picked;
          break;
      }
    });
    await DatabaseService.instance.updateDesign(_design);
  }

  Future<void> _clearDate(String field) async {
    setState(() {
      switch (field) {
        case 'cad':
          _design.cadApprovedDate = null;
          break;
        case 'strike':
          _design.strikeOffDate = null;
          break;
        case 'rotary':
          _design.rotaryScreenDate = null;
          break;
      }
    });
    await DatabaseService.instance.updateDesign(_design);
  }

  DateTime? _fieldDate(String field) {
    switch (field) {
      case 'cad':
        return _design.cadApprovedDate;
      case 'strike':
        return _design.strikeOffDate;
      case 'rotary':
        return _design.rotaryScreenDate;
    }
    return null;
  }

  Widget _stageTile(
      {required String title, required String field, required IconData icon}) {
    final date = _fieldDate(field);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon,
            color: date != null ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: Text(date != null
            ? DateFormat('dd MMM yyyy').format(date)
            : 'Not done yet'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () => _pickAndSetDate(field),
            ),
            if (date != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _clearDate(field),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Design?'),
        content: Text('Delete "${_design.name}" permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true && _design.id != null) {
      await DatabaseService.instance.deleteDesign(_design.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_design.name),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              color: Colors.deepPurple.withOpacity(0.08),
              child: ListTile(
                leading: const Icon(Icons.inbox, color: Colors.deepPurple),
                title: const Text('Design Received'),
                subtitle: Text(
                    DateFormat('dd MMM yyyy').format(_design.receivedDate)),
              ),
            ),
            const SizedBox(height: 12),
            _stageTile(
                title: 'CAD / Design Approved',
                field: 'cad',
                icon: Icons.check_circle_outline),
            _stageTile(
                title: 'Strike Off Given',
                field: 'strike',
                icon: Icons.print_outlined),
            _stageTile(
                title: 'Rotary Screen Printed',
                field: 'rotary',
                icon: Icons.loop),
            if (_design.remarks != null && _design.remarks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('Remarks'),
                  subtitle: Text(_design.remarks!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
