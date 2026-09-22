import '../models/design.dart';

/// Weeks run Monday-Saturday (Sunday is a day off and never starts a
/// new week). Weeks are computed continuously — never reset in the
/// middle of a Monday-Saturday span — and a week belongs to whichever
/// calendar month its Saturday (end date) falls in. So for September
/// 2026: WEEK 1 = 31-08-2026 to 05-09-2026 (Saturday 05-09 is in
/// September, so this week is September's Week 1 even though it
/// starts in August), WEEK 2 = 07-09 to 12-09, WEEK 3 = 14-09 to
/// 19-09, WEEK 4 = 21-09 to 26-09. The week starting 28-09 has its
/// Saturday (03-10) in October, so it becomes October's Week 1 —
/// this mirrors the app's Excel export and the live Sheet/xlsx sync
/// exactly, so the numbers always match.
class WeekUtils {
  static DateTime _mondayOf(DateTime date) {
    final offset = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: offset));
  }

  /// All week-start Mondays whose Saturday falls within [month].
  static List<DateTime> _weekStartsForMonth(DateTime month) {
    final searchStart =
        DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));
    final searchEnd =
        DateTime(month.year, month.month + 1, 0).add(const Duration(days: 7));

    final result = <DateTime>[];
    var monday = _mondayOf(searchStart);
    while (!monday.isAfter(searchEnd)) {
      final saturday = monday.add(const Duration(days: 5));
      if (saturday.year == month.year && saturday.month == month.month) {
        result.add(monday);
      }
      monday = monday.add(const Duration(days: 7));
    }
    return result;
  }

  /// 1-based week number of [date] within whichever month-section its
  /// week belongs to (per the Saturday-anchor rule above).
  static int weekOfMonth(DateTime date) {
    final monday = _mondayOf(date);
    final saturday = monday.add(const Duration(days: 5));
    final sectionMonth = DateTime(saturday.year, saturday.month);
    final starts = _weekStartsForMonth(sectionMonth);
    final idx = starts.indexWhere((m) => m == monday);
    return idx == -1 ? 1 : idx + 1;
  }

  static String weekLabel(DateTime date) => 'Week ${weekOfMonth(date)}';

  static int weeksInMonth(DateTime month) => _weekStartsForMonth(month).length;

  /// Returns the Monday and Saturday dates for the given month/week number.
  static (DateTime start, DateTime end) weekDateRange(
      DateTime month, int week) {
    final starts = _weekStartsForMonth(month);
    final start = starts[week - 1];
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
