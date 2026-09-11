import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';

/// A GitHub-style contribution heatmap showing designs received per day
/// over the last few weeks. Each cell is large enough to tap comfortably.
class DesignHeatmap extends StatelessWidget {
  final List<Design> designs;
  final int weeksToShow;

  const DesignHeatmap({
    super.key,
    required this.designs,
    this.weeksToShow = 6,
  });

  Map<DateTime, int> _countsByDay() {
    final counts = <DateTime, int>{};
    for (final d in designs) {
      final day = DateTime(
          d.receivedDate.year, d.receivedDate.month, d.receivedDate.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return counts;
  }

  Color _colorForCount(BuildContext context, int count) {
    final base = Theme.of(context).colorScheme.primary;
    if (count == 0) return base.withOpacity(0.08);
    if (count == 1) return base.withOpacity(0.35);
    if (count == 2) return base.withOpacity(0.6);
    if (count == 3) return base.withOpacity(0.8);
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _countsByDay();
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Align grid so the last column ends on today, weeks run Sun-Sat.
    final daysBack = weeksToShow * 7 - 1;
    final startDay = today.subtract(Duration(days: daysBack));
    final gridStart = startDay.subtract(Duration(days: startDay.weekday % 7));

    final weeks = <List<DateTime>>[];
    for (int w = 0; w < weeksToShow + 1; w++) {
      final week = <DateTime>[];
      for (int d = 0; d < 7; d++) {
        week.add(gridStart.add(Duration(days: w * 7 + d)));
      }
      weeks.add(week);
    }

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_view_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text('Activity (last ${weeksToShow + 1} weeks)',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: dayLabels
                        .map((l) => SizedBox(
                              width: 18,
                              height: 34,
                              child: Center(
                                child: Text(l,
                                    style: const TextStyle(fontSize: 10)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(width: 4),
                  ...weeks.map((week) => Column(
                        children: week.map((day) {
                          final isFuture = day.isAfter(today);
                          final count = counts[day] ?? 0;
                          return Padding(
                            padding: const EdgeInsets.all(2),
                            child: GestureDetector(
                              onTap: isFuture
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          duration:
                                              const Duration(seconds: 2),
                                          content: Text(
                                            '${DateFormat('dd MMM yyyy').format(day)}: $count design${count == 1 ? '' : 's'} received',
                                          ),
                                        ),
                                      );
                                    },
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: isFuture
                                      ? Colors.transparent
                                      : _colorForCount(context, count),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Less', style: TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                ...List.generate(5, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colorForCount(context, i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                const Text('More', style: TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
