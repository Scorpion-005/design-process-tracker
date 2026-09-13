import '../models/design.dart';

/// Weeks run Monday-Saturday (Sunday is treated as a day off and does not
/// start a new week bucket). Week numbers restart at the start of each
/// month, anchored to the first Monday on/before the 1st of the month.
class WeekUtils {
  static int weekOfMonth(DateTime date) {
    final firstOfMonth = DateTime(date.year, date.month, 1);
    final firstMondayOffset = (firstOfMonth.weekday - DateTime.monday) % 7;
    final firstWeekMonday =
        firstOfMonth.subtract(Duration(days: firstMondayOffset));

    final dateMondayOffset = (date.weekday - DateTime.monday) % 7;
    final mondayOfDate = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: dateMondayOffset));

    final weeksDiff = mondayOfDate.difference(firstWeekMonday).inDays ~/ 7;
    return weeksDiff + 1;
  }

  static String weekLabel(DateTime date) => 'Week ${weekOfMonth(date)}';

  static int weeksInMonth(DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return weekOfMonth(lastDay);
  }

  /// Returns the Monday and Saturday dates for the given month/week number.
  static (DateTime start, DateTime end) weekDateRange(
      DateTime month, int week) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final firstMondayOffset = (firstOfMonth.weekday - DateTime.monday) % 7;
    final firstWeekMonday =
        firstOfMonth.subtract(Duration(days: firstMondayOffset));
    final start = firstWeekMonday.add(Duration(days: (week - 1) * 7));
    final end = start.add(const Duration(days: 5));
    return (start, end);
  }

  /// Returns designs whose `receivedDate` falls within this month/week's
  /// actual Monday-Saturday date range (spillover days from the previous
  /// or next calendar month are included correctly).
  static List<Design> designsReceivedInWeek(
      List<Design> all, DateTime month, int week) {
    final (start, end) = weekDateRange(month, week);
    return all.where((d) {
      final rd = DateTime(
          d.receivedDate.year, d.receivedDate.month, d.receivedDate.day);
      return !rd.isBefore(start) && !rd.isAfter(end);
    }).toList();
  }

  static Map<int, int> weeklyReceivedCounts(List<Design> all, DateTime month) {
    final totalWeeks = weeksInMonth(month);
    final counts = <int, int>{
      for (var w = 1; w <= totalWeeks; w++) w: 0,
    };
    for (var w = 1; w <= totalWeeks; w++) {
      counts[w] = designsReceivedInWeek(all, month, w).length;
    }
    return counts;
  }

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
}
