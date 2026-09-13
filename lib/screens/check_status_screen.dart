import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';
import '../services/database_service.dart';

class CheckStatusScreen extends StatefulWidget {
  const CheckStatusScreen({super.key});

  @override
  State<CheckStatusScreen> createState() => _CheckStatusScreenState();
}

class _CheckStatusScreenState extends State<CheckStatusScreen> {
  String _query = '';
  DesignStage? _selectedStage;

  List<Design> _filter(List<Design> all) {
    if (_selectedStage == null) return [];
    return all.where((d) {
      final matchesStage = d.currentStage == _selectedStage;
      final matchesQuery = _query.trim().isEmpty ||
          (d.rpNo ?? '').toLowerCase().contains(_query.trim().toLowerCase());
      return matchesStage && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Status')),
      body: StreamBuilder<List<Design>>(
        stream: DatabaseService.instance.watchAllDesigns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          final results = _filter(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Check Status (Enter RP No)',
                    hintText: 'e.g. RP001',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: DesignStage.values.map((stage) {
                      return RadioListTile<DesignStage>(
                        title: Text(stage.label),
                        value: stage,
                        groupValue: _selectedStage,
                        onChanged: (v) => setState(() => _selectedStage = v),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _selectedStage == null
                    ? const Center(
                        child:
                            Text('Select a process above to check status'))
                    : results.isEmpty
                        ? const Center(child: Text('No matching designs'))
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: results.length,
                            itemBuilder: (context, i) {
                              final d = results[i];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(
                                      d.rpNo != null && d.rpNo!.isNotEmpty
                                          ? '${d.rpNo} - ${d.name}'
                                          : d.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      'Received: ${DateFormat('dd MMM yyyy').format(d.receivedDate)}'),
                                  trailing: Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
