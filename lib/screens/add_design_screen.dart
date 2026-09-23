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
  final _rpNoCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  DateTime _receivedDate = DateTime.now();

  // Company Name autocomplete: backed by every distinct company name
  // already saved in Firestore. A brand-new name typed here becomes a
  // suggestion for everyone the next time this screen loads.
  String _companyName = '';
  List<String> _companyOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCompanyOptions();
  }

  Future<void> _loadCompanyOptions() async {
    final names = await DatabaseService.instance.fetchDistinctCompanyNames();
    if (mounted) setState(() => _companyOptions = names);
  }

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
      rpNo: _rpNoCtrl.text.trim().isEmpty
          ? 'New Design'
          : _rpNoCtrl.text.trim().toUpperCase(),
      name: _nameCtrl.text.trim(),
      customerName: _companyName.trim().isEmpty ? null : _companyName.trim(),
      buyerName:
          _buyerCtrl.text.trim().isEmpty ? null : _buyerCtrl.text.trim(),
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
                controller: _rpNoCtrl,
                decoration: const InputDecoration(
                  labelText: 'RP No',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final value = v.trim().toUpperCase();
                  final regex = RegExp(r'^RP\s?\d+\/\d+C$');
                  if (!regex.hasMatch(value)) {
                    return 'Format should be like RP 12345678/10C';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Design Name',
                    border: OutlineInputBorder()),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              RawAutocomplete<String>(
                initialValue: TextEditingValue(text: _companyName),
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.trim().isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  final query = value.text.toLowerCase();
                  return _companyOptions
                      .where((name) => name.toLowerCase().contains(query));
                },
                onSelected: (selection) {
                  setState(() => _companyName = selection);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _companyName = v,
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              title: Text(option),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder()),
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
