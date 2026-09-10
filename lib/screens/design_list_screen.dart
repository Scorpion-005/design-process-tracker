import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';
import '../services/database_service.dart';
import 'design_detail_screen.dart';

class DesignListScreen extends StatefulWidget {
  const DesignListScreen({super.key});

  @override
  State<DesignListScreen> createState() => _DesignListScreenState();
}

class _DesignListScreenState extends State<DesignListScreen> {
  List<Design> _all = [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await DatabaseService.instance.getAllDesigns();
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  Color _stageColor(DesignStage s) {
    switch (s) {
      case DesignStage.received:
        return Colors.blueGrey;
      case DesignStage.cadApproved:
        return Colors.blue;
      case DesignStage.strikeOff:
        return Colors.orange;
      case DesignStage.rotaryScreen:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _all
        .where((d) => d.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Designs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search design name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('No designs yet'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            final stage = d.currentStage;
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(d.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    'Received: ${DateFormat('dd MMM yyyy').format(d.receivedDate)}'),
                                trailing: Chip(
                                  label: Text(stage.label,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.white)),
                                  backgroundColor: _stageColor(stage),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            DesignDetailScreen(design: d)),
                                  );
                                  _load();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
