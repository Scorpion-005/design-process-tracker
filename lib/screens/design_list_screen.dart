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
  String _query = '';

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
            child: StreamBuilder<List<Design>>(
              stream: DatabaseService.instance.watchAllDesigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snapshot.data ?? [];
                final filtered = all
                    .where((d) =>
                        d.name.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No designs yet'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final d = filtered[i];
                    final stage = d.currentStage;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(
                            d.rpNo != null && d.rpNo!.isNotEmpty
                                ? '${d.rpNo} - ${d.name}'
                                : d.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            '${(d.customerName != null && d.customerName!.isNotEmpty) ? '${d.customerName} • ' : ''}Received: ${DateFormat('dd MMM yyyy').format(d.receivedDate)}'),
                        trailing: Chip(
                          label: Text(stage.label,
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white)),
                          backgroundColor: _stageColor(stage),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DesignDetailScreen(design: d)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
