import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';
import '../services/database_service.dart';

class AddDesignScreen extends StatefulWidget {
  const AddDesignScreen({super.key});

  @override
  State<AddDesignScreen> createState() => _AddDesignScreenState();
}

class _AddDesignScreenState extends State<AddDesignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  DateTime _receivedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _receivedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _receivedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final design = Design(
      name: _nameCtrl.text.trim(),
      remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
      receivedDate: _receivedDate,
    );
    await DatabaseService.instance.insertDesign(design);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Design')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Design Name / Code',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Design Received Date'),
                subtitle:
                    Text(DateFormat('dd MMM yyyy').format(_receivedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarksCtrl,
                decoration: const InputDecoration(
                    labelText: 'Remarks (optional)',
                    border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Design'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
