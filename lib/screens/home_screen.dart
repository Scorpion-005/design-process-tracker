import 'package:flutter/material.dart';
import '../models/design.dart';
import '../services/database_service.dart';
import '../services/week_utils.dart';
import '../services/export_service.dart';
import '../widgets/design_heatmap.dart';
import '../main.dart';
import 'add_design_screen.dart';
import 'design_list_screen.dart';
import 'analytics_screen.dart';
import 'check_status_screen.dart';

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
      appBar: AppBar(
        title: const Text('Design Process Tracker'),
        actions: [
          IconButton(
            tooltip: 'Export & Share (Excel)',
            icon: const Icon(Icons.ios_share),
            onPressed: _designs.isEmpty
                ? null
                : () => ExportService.exportAndShare(_designs),
          ),
          AnimatedBuilder(
            animation: themeService,
            builder: (context, _) => IconButton(
              tooltip: 'Toggle dark mode',
              icon: Icon(
                  themeService.isDark ? Icons.dark_mode : Icons.light_mode),
              onPressed: () => themeService.toggle(!themeService.isDark),
            ),
          ),
        ],
      ),
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
                  const SizedBox(height: 14),
                  Text('This Week (Week $currentWeek)',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 16),
                  DesignHeatmap(designs: _designs),
                  const SizedBox(height: 20),
                  _MenuTile(
                    icon: Icons.insights,
                    title: 'Weekly Funnel & Analytics',
                    subtitle:
                        'Week-wise received vs approved vs strike off vs rotary',
                    color: Colors.teal,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => AnalyticsScreen(designs: _designs)),
                      );
                    },
                  ),
                  _MenuTile(
                    icon: Icons.list_alt,
                    title: 'All Designs',
                    subtitle: 'View & update stage dates',
                    color: Colors.orange,
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
                    icon: Icons.fact_check_outlined,
                    title: 'Check Status',
                    subtitle: 'Search RP No and check process status',
                    color: Colors.indigo,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CheckStatusScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDesignScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Design'),
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
      color: color.withOpacity(0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          title: Text(title,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500)),
          trailing: Text(value,
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: color)),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text('W$week',
                style: TextStyle(
                    fontSize: 13,
                    color: highlight ? Colors.white : null)),
            const SizedBox(height: 6),
            Text('$count',
                style: TextStyle(
                    fontSize: 18,
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
  final Color color;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
