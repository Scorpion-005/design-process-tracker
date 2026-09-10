import 'package:flutter/material.dart';
import '../models/design.dart';
import '../services/database_service.dart';
import '../services/week_utils.dart';
import 'add_design_screen.dart';
import 'design_list_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Design> _designs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await DatabaseService.instance.getAllDesigns();
    setState(() {
      _designs = all;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayCount = _designs
        .where((d) =>
            d.receivedDate.year == today.year &&
            d.receivedDate.month == today.month &&
            d.receivedDate.day == today.day)
        .length;

    final weekCounts = WeekUtils.weeklyReceivedCounts(_designs, today);
    final currentWeek = WeekUtils.weekOfMonth(today);

    return Scaffold(
      appBar: AppBar(title: const Text('Design Process Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatCard(
                    title: "Today's Designs",
                    value: '$todayCount',
                    color: Colors.deepPurple,
                    icon: Icons.today,
                  ),
                  const SizedBox(height: 12),
                  Text('This Week (Week $currentWeek)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [1, 2, 3, 4]
                        .map((w) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: _WeekMiniCard(
                                  week: w,
                                  count: weekCounts[w] ?? 0,
                                  highlight: w == currentWeek,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  _MenuTile(
                    icon: Icons.add_circle_outline,
                    title: 'Add New Design',
                    subtitle: 'Log a new design received today',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddDesignScreen()),
                      );
                      _load();
                    },
                  ),
                  _MenuTile(
                    icon: Icons.list_alt,
                    title: 'All Designs',
                    subtitle: 'View & update stage dates',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DesignListScreen()),
                      );
                      _load();
                    },
                  ),
                  _MenuTile(
                    icon: Icons.insights,
                    title: 'Weekly Funnel & Analytics',
                    subtitle:
                        'Week-wise received vs approved vs strike off vs rotary',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AnalyticsScreen(designs: _designs)),
                      );
                    },
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDesignScreen()),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}

class _WeekMiniCard extends StatelessWidget {
  final int week;
  final int count;
  final bool highlight;

  const _WeekMiniCard(
      {required this.week, required this.count, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? Colors.deepPurple : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text('W$week',
                style: TextStyle(color: highlight ? Colors.white : null)),
            const SizedBox(height: 4),
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.white : null)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
