import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/design.dart';
import 'week_utils.dart';

class ExportService {
  static final _fmt = DateFormat('dd-MM-yyyy');

  /// Builds an Excel (.xlsx) report matching the factory's weekly report
  /// layout: Week -> Date -> Customer groups, with RP numbers stacked,
  /// day-gap ("Between") columns, and a week total row.
  static Future<void> exportAndShare(List<Design> designs) async {
    final excelFile = Excel.createExcel();
    final sheetName = excelFile.getDefaultSheet() ?? 'Sheet1';
    final sheet = excelFile[sheetName];

    final sorted = List<Design>.from(designs)
      ..sort((a, b) => a.receivedDate.compareTo(b.receivedDate));

    // Group by year-month, preserving chronological order.
    final monthOrder = <String>[];
    final monthGroups = <String, List<Design>>{};
    for (final d in sorted) {
      final key = '${d.receivedDate.year}-${d.receivedDate.month}';
      if (!monthGroups.containsKey(key)) {
        monthGroups[key] = [];
        monthOrder.add(key);
      }
      monthGroups[key]!.add(d);
    }

    int row = 0;
    int overallStrikeOff = 0;
    int overallRotary = 0;

    for (final monthKey in monthOrder) {
      final monthDesigns = monthGroups[monthKey]!;
      final monthLabel =
          DateFormat('MMMM yyyy').format(monthDesigns.first.receivedDate);

      _setCell(sheet, 0, row, '${monthLabel.toUpperCase()} WEEKLY REPORTS',
          bold: true);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row),
      );
      row++;

      const headers = [
        'WEEKS',
        'DATES',
        "CUSTOMER'S",
        'NO.D',
        'NO.D FINISH',
        'NO.D PENDING',
        'RP NO.',
        'BETWEEN',
        'DESIGN MAIL SEND',
        'BETWEEN',
        'S/OFF',
        'BETWEEN',
        'D ROTARY',
      ];
      for (int c = 0; c < headers.length; c++) {
        _setCell(sheet, c, row, headers[c], bold: true);
      }
      row++;

      // Group by week (Monday-Saturday), preserving order.
      final weekOrder = <int>[];
      final weekGroups = <int, List<Design>>{};
      for (final d in monthDesigns) {
        final w = WeekUtils.weekOfMonth(d.receivedDate);
        if (!weekGroups.containsKey(w)) {
          weekGroups[w] = [];
          weekOrder.add(w);
        }
        weekGroups[w]!.add(d);
      }

      for (final weekNum in weekOrder) {
        final weekDesigns = weekGroups[weekNum]!;
        final weekStartRow = row;
        int weekTotal = 0;
        int weekFinish = 0;

        // Group by received date within the week.
        final dateOrder = <DateTime>[];
        final dateGroups = <DateTime, List<Design>>{};
        for (final d in weekDesigns) {
          final day = DateTime(d.receivedDate.year, d.receivedDate.month,
              d.receivedDate.day);
          if (!dateGroups.containsKey(day)) {
            dateGroups[day] = [];
            dateOrder.add(day);
          }
          dateGroups[day]!.add(d);
        }

        for (final day in dateOrder) {
          final dayDesigns = dateGroups[day]!;
          final dateStartRow = row;

          // Group by customer within the date.
          final custOrder = <String>[];
          final custGroups = <String, List<Design>>{};
          for (final d in dayDesigns) {
            final key = (d.customerName ?? '').trim();
            if (!custGroups.containsKey(key)) {
              custGroups[key] = [];
              custOrder.add(key);
            }
            custGroups[key]!.add(d);
          }

          for (final custKey in custOrder) {
            final group = custGroups[custKey]!;
            final noD = group.length;
            final noFinish =
                group.where((d) => d.rotaryScreenDate != null).length;
            final noPending = noD - noFinish;

            final rpNos = group
                .map((d) => d.rpNo ?? '')
                .where((s) => s.isNotEmpty)
                .join('\n');

            final cadDates = group
                .map((d) => d.cadApprovedDate)
                .whereType<DateTime>()
                .toSet()
                .toList()
              ..sort();
            final strikeDates = group
                .map((d) => d.strikeOffDate)
                .whereType<DateTime>()
                .toSet()
                .toList()
              ..sort();
            final rotaryDates = group
                .map((d) => d.rotaryScreenDate)
                .whereType<DateTime>()
                .toSet()
                .toList()
              ..sort();

            overallStrikeOff += group.where((d) => d.strikeOffDate != null).length;
            overallRotary += group.where((d) => d.rotaryScreenDate != null).length;

            final between1 =
                cadDates.isNotEmpty ? cadDates.first.difference(day).inDays : null;
            final between2 = (cadDates.isNotEmpty && strikeDates.isNotEmpty)
                ? strikeDates.first.difference(cadDates.first).inDays
                : null;
            final between3 = (strikeDates.isNotEmpty && rotaryDates.isNotEmpty)
                ? rotaryDates.first.difference(strikeDates.first).inDays
                : null;

            _setCell(sheet, 2, row, custKey);
            _setCell(sheet, 3, row, noD);
            _setCell(sheet, 4, row, noFinish);
            _setCell(sheet, 5, row, noPending);
            _setCell(sheet, 6, row, rpNos);
            _setCell(sheet, 7, row, between1);
            _setCell(sheet, 8, row,
                cadDates.map((d) => _fmt.format(d)).join('\n'));
            _setCell(sheet, 9, row, between2);
            _setCell(sheet, 10, row,
                strikeDates.map((d) => _fmt.format(d)).join('\n'));
            _setCell(sheet, 11, row, between3);
            _setCell(sheet, 12, row,
                rotaryDates.map((d) => _fmt.format(d)).join('\n'));

            weekTotal += noD;
            weekFinish += noFinish;
            row++;
          }

          final dateEndRow = row - 1;
          _setCell(sheet, 1, dateStartRow, _fmt.format(day));
          if (dateEndRow > dateStartRow) {
            sheet.merge(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dateStartRow),
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dateEndRow),
            );
          }
        }

        final weekEndRow = row - 1;
        _setCell(sheet, 0, weekStartRow, 'WEEK $weekNum');
        if (weekEndRow > weekStartRow) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: weekStartRow),
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: weekEndRow),
          );
        }

        final weekPending = weekTotal - weekFinish;
        _setCell(sheet, 2, row, "WEEK $weekNum TOTAL DESIGN'S=", bold: true);
        _setCell(sheet, 3, row, weekTotal, bold: true);
        _setCell(sheet, 4, row, weekFinish, bold: true);
        _setCell(sheet, 5, row, weekPending, bold: true);
        _setCell(sheet, 8, row, "PENDING DESIGN'S=", bold: true);
        _setCell(sheet, 9, row, weekPending, bold: true);
        row++;
        row++; // blank spacer row between weeks
      }
      row++; // extra blank row between months
    }

    // Overall summary at the very end.
    row++;
    _setCell(sheet, 0, row, 'No. of Designs Received', bold: true);
    _setCell(sheet, 1, row, designs.length, bold: true);
    row++;
    _setCell(sheet, 0, row, 'No. of Designs Strike Off', bold: true);
    _setCell(sheet, 1, row, overallStrikeOff, bold: true);
    row++;
    _setCell(sheet, 0, row, 'No. of Designs Rotary Screen', bold: true);
    _setCell(sheet, 1, row, overallRotary, bold: true);

    final bytes = excelFile.encode();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/design_tracker_export_$stamp.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Design Process Tracker - Weekly Report',
      subject: 'Design Tracker Export ($stamp)',
    );
  }

  static void _setCell(Sheet sheet, int col, int row, Object? value,
      {bool bold = false}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value == null) {
      cell.value = TextCellValue('');
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }
    if (bold) {
      cell.cellStyle = CellStyle(bold: true);
    }
  }
}
