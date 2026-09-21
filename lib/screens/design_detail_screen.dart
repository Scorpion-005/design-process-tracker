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

  Future<String?> _askDesignerName({String? initialName}) async {
    final ctrl = TextEditingController(text: initialName ?? '');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Designer Name?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Designer name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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

    String? designerName;
    if (field != 'mailsend') {
      designerName = await _askDesignerName(initialName: _fieldBy(field));
      if (designerName == null) return; // cancelled
    }

    setState(() {
      switch (field) {
        case 'mailsend':
          _design.designMailSendDate = picked;
          break;
        case 'cad':
          _design.cadApprovedDate = picked;
          _design.cadApprovedBy =
              (designerName == null || designerName.isEmpty) ? null : designerName;
          break;
        case 'strike':
          _design.strikeOffDate = picked;
          _design.strikeOffBy =
              (designerName == null || designerName.isEmpty) ? null : designerName;
          break;
        case 'rotary':
          _design.rotaryScreenDate = picked;
          _design.rotaryScreenBy =
              (designerName == null || designerName.isEmpty) ? null : designerName;
          break;
      }
    });
    await DatabaseService.instance.updateDesign(_design);
  }

  Future<void> _clearDate(String field) async {
    setState(() {
      switch (field) {
        case 'mailsend':
          _design.designMailSendDate = null;
          break;
        case 'cad':
          _design.cadApprovedDate = null;
          _design.cadApprovedBy = null;
          break;
        case 'strike':
          _design.strikeOffDate = null;
          _design.strikeOffBy = null;
          break;
        case 'rotary':
          _design.rotaryScreenDate = null;
          _design.rotaryScreenBy = null;
          break;
      }
    });
    await DatabaseService.instance.updateDesign(_design);
  }

  DateTime? _fieldDate(String field) {
    switch (field) {
      case 'mailsend':
        return _design.designMailSendDate;
      case 'cad':
        return _design.cadApprovedDate;
      case 'strike':
        return _design.strikeOffDate;
      case 'rotary':
        return _design.rotaryScreenDate;
    }
    return null;
  }

  String? _fieldBy(String field) {
    switch (field) {
      case 'cad':
        return _design.cadApprovedBy;
      case 'strike':
        return _design.strikeOffBy;
      case 'rotary':
        return _design.rotaryScreenBy;
    }
    return null;
  }

  Widget _stageTile(
      {required String title, required String field, required IconData icon}) {
    final date = _fieldDate(field);
    final by = _fieldBy(field);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon,
            color: date != null ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: Text(date != null
            ? '${DateFormat('dd MMM yyyy').format(date)}${by != null && by.isNotEmpty ? ' · $by' : ''}'
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

  Future<void> _editInfo() async {
    final rpCtrl = TextEditingController(text: _design.rpNo ?? '');
    final companyCtrl = TextEditingController(text: _design.customerName ?? '');
    final customerCtrl = TextEditingController(text: _design.buyerName ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Design Info'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rpCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'RP No',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: companyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Company Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: customerCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final newRpNo = rpCtrl.text.trim().isEmpty
        ? 'New Design'
        : rpCtrl.text.trim().toUpperCase();
    final newCompany = companyCtrl.text.trim();
    final newCustomer = customerCtrl.text.trim();

    setState(() {
      _design = Design(
        id: _design.id,
        rpNo: newRpNo,
        customerName: newCompany.isEmpty ? null : newCompany,
        buyerName: newCustomer.isEmpty ? null : newCustomer,
        name: _design.name,
        remarks: _design.remarks,
        receivedDate: _design.receivedDate,
        designMailSendDate: _design.designMailSendDate,
        cadApprovedDate: _design.cadApprovedDate,
        strikeOffDate: _design.strikeOffDate,
        rotaryScreenDate: _design.rotaryScreenDate,
        cadApprovedBy: _design.cadApprovedBy,
        strikeOffBy: _design.strikeOffBy,
        rotaryScreenBy: _design.rotaryScreenBy,
      );
    });
    await DatabaseService.instance.updateDesign(_design);
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
        title: Text(
            _design.rpNo != null && _design.rpNo!.isNotEmpty
                ? '${_design.rpNo} - ${_design.name}'
                : _design.name),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editInfo),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (_design.customerName != null && _design.customerName!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.apartment_outlined),
                  title: const Text('Company'),
                  subtitle: Text(_design.customerName!),
                ),
              ),
            if (_design.customerName != null && _design.customerName!.isNotEmpty)
              const SizedBox(height: 12),
            if (_design.buyerName != null && _design.buyerName!.isNotEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Customer'),
                  subtitle: Text(_design.buyerName!),
                ),
              ),
            if (_design.buyerName != null && _design.buyerName!.isNotEmpty)
              const SizedBox(height: 12),
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
                title: 'Design Mail Send',
                field: 'mailsend',
                icon: Icons.forward_to_inbox_outlined),
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
