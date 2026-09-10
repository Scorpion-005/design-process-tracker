import '../models/design.dart';

/// Groups dates of the current month into Week 1-4(+5) buckets,
/// where Week N = days (N-1)*7+1 .. N*7 of the month.
class WeekUtils {
  static int weekOfMonth(DateTime date) {
    return ((date.day - 1) / 7).floor() + 1;
  }

  /// Returns designs whose `receivedDate` falls in the given month/week.
  static List<Design> designsReceivedInWeek(
      List<Design> all, DateTime month, int week) {
    return all.where((d) {
      final rd = d.receivedDate;
      return rd.year == month.year &&
          rd.month == month.month &&
          weekOfMonth(rd) == week;
    }).toList();
  }

  /// Map of week number (1-5) -> count of designs received that week,
  /// for the given month.
  static Map<int, int> weeklyReceivedCounts(List<Design> all, DateTime month) {
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final d in all) {
      final rd = d.receivedDate;
      if (rd.year == month.year && rd.month == month.month) {
        final w = weekOfMonth(rd);
        counts[w] = (counts[w] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// For a set of designs received in a given week, how many have moved
  /// on to each subsequent stage.
  static Map<DesignStage, int> funnelForWeek(List<Design> weekDesigns) {
    int cad = 0, strike = 0, rotary = 0;
    for (final d in weekDesigns) {
      if (d.cadApprovedDate != null) cad++;
      if (d.strikeOffDate != null) strike++;
      if (d.rotaryScreenDate != null) rotary++;
    }
    return {
      DesignStage.received: weekDesigns.length,
      DesignStage.cadApproved: cad,
      DesignStage.strikeOff: strike,
      DesignStage.rotaryScreen: rotary,
    };
  }
