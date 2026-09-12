import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/design.dart';

/// A clean bar chart showing designs received per day over the last 7 days.
class DesignHeatmap extends StatelessWidget {
  final List<Design> designs;

  const DesignHeatmap({super.key, required this.designs});

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    final counts = <DateTime, int>{};
    for (final d in designs) {
      final day = DateTime(
          d.receivedDate.year, d.receivedDate.month, d.receivedDate.day);
      counts[day] = (counts[day] ?? 0) + 1;
    }

    final maxCount = days
        .map((d) => counts[d] ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final chartMax = maxCount == 0 ? 4.0 : (maxCount + 1).toDouble();

    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: primary),
                const SizedBox(width: 6),
                Text('Last 7 Days',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 140,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = days[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('dd MMM').format(day)}\n${rod.toY.toInt()} design${rod.toY.toInt() == 1 ? '' : 's'}',
                          const TextStyle(
                              color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final isToday = days[i] == today;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat('E').format(days[i]).substring(0, 1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday ? primary : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(days.length, (i) {
                    final count = (counts[days[i]] ?? 0).toDouble();
                    final isToday = days[i] == today;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: count,
                          width: 22,
                          borderRadius: BorderRadius.circular(6),
                          color: isToday
                              ? primary
                              : primary.withOpacity(0.45),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
