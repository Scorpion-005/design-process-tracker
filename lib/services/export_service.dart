import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/design.dart';

class ExportService {
  static final _fmt = DateFormat('dd-MM-yyyy');

  // Highlight colour for the two lead-time columns (Design Lead Time,
  // S/OFF Lead Time) so they stand out from the rest of the sheet.
  static final _leadTimeHighlight = ExcelColor.fromHexString('#FFE699');
  static final _headerFill = ExcelColor.fromHexString('#D9D2E9');
  static final _redFont = ExcelColor.fromHexString('#FF0000');

  /// Monday of the Monday–Saturday work-week containing [date]
  /// (matches WeekUtils' own Monday-anchoring, but is computed
  /// continuously here — it is never reset at a calendar-month
  /// boundary, so a week that spans two months stays a single week).
  static DateTime _mondayOf(DateTime date) {
    final offset = (date.weekday - DateTime.monday) % 7;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: offset));
  }

  /// Builds an Excel (.xlsx) report matching the factory's physical
  /// "Weekly Reports" sheet exactly:
  /// WEEKS | DATES | CUSTOMER'S | NO DESIGN | DESIGN FINISH | DESIGN PENDING |
  /// RP NO | DESIGN MAIL SEND | DESIGN LEAD TIME | CAD APP MAIL |
  /// S/OFF DATE | S/OFF LEAD TIME | D ROTARY
  ///
  /// Rules (matching the physical sheet, per Scorpion):
  /// - A Monday–Saturday week is never split across two calendar
  ///   months. Its month-section is decided by the week's Saturday
  ///   (end date), and weeks are renumbered 1, 2, 3... within that
  ///   section in chronological order.
  /// - One row per design/RP No. — RP numbers are never combined
  ///   into a single cell, even when the same customer has more
  ///   than one design on the same date.
  /// - DESIGN FINISH = 1 once the Design Mail Send date is set.
  /// - DESIGN LEAD TIME = days from Design Received date to
  ///   Design Mail Send date.
  /// - S/OFF LEAD TIME = days from CAD App Mail date to S/OFF date.
  /// - All cell text is centre-aligned.
  /// - CAD APP MAIL / S/OFF DATE / D ROTARY: empty cells show "-" in
  ///   red so pending stages are visually flagged.
  /// - DESIGN LEAD TIME / S/OFF LEAD TIME columns get a distinct
  ///   highlight colour.
  static Future<void> exportAndShare(List<Design> designs) async {
    final excelFile = Excel.createExcel();
    final sheetName = excelFile.getDefaultSheet() ?? 'Sheet1';
    final sheet = excelFile[sheetName];

    final sorted = List<Design>.from(designs)
      ..sort((a, b) {
        final byDate = a.receivedDate.compareTo(b.receivedDate);
        if (byDate != 0) return byDate;
        final byCustomer =
            (a.customerName ?? '').compareTo(b.customerName ?? '');
        if (byCustomer != 0) return byCustomer;
        return (a.rpNo ?? '').compareTo(b.rpNo ?? '');
      });

    // 1. Bucket designs into continuous Monday-Saturday weeks
    // (never reset at a month boundary).
    final weekOrder = <DateTime>[]; // chronological list of Mondays
    final weekGroups = <DateTime, List<Design>>{};
    for (final d in sorted) {
      final monday = _mondayOf(d.receivedDate);
      if (!weekGroups.containsKey(monday)) {
        weekGroups[monday] = [];
        weekOrder.add(monday);
      }
      weekGroups[monday]!.add(d);
    }

    // 2. Assign each week to a month-section based on its Saturday
    // (the week's end date) — so a week that starts in the previous
    // month but mostly falls in the new month reports under the new
    // month, matching the physical sheet.
    final sectionOrder = <String>[];
    final sectionWeeks = <String, List<DateTime>>{};
    for (final monday in weekOrder) {
      final saturday = monday.add(const Duration(days: 5));
      final sectionKey = '${saturday.year}-${saturday.month}';
      if (!sectionWeeks.containsKey(sectionKey)) {
        sectionWeeks[sectionKey] = [];
        sectionOrder.add(sectionKey);
      }
      sectionWeeks[sectionKey]!.add(monday);
    }

    int row = 0;

    for (final sectionKey in sectionOrder) {
      final mondaysInSection = sectionWeeks[sectionKey]!;
      final sectionSaturday =
          mondaysInSection.first.add(const Duration(days: 5));
      final monthLabel = DateFormat('MMMM yyyy').format(sectionSaturday);

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
        'NO DESIGN',
        'DESIGN FINISH',
        'DESIGN PENDING',
        'RP NO',
        'DESIGN MAIL SEND',
        'DESIGN LEAD TIME',
        'CAD APP MAIL',
        'S/OFF DATE',
        'S/OFF LEAD TIME',
        'D ROTARY',
      ];
      for (int c = 0; c < headers.length; c++) {
        final isLeadTimeCol = c == 8 || c == 11;
        _setCell(sheet, c, row, headers[c],
            bold: true,
            background: isLeadTimeCol ? _leadTimeHighlight : _headerFill);
      }
      row++;

      // Renumber weeks 1..N within this section, in chronological order.
      for (int wIdx = 0; wIdx < mondaysInSection.length; wIdx++) {
        final weekNum = wIdx + 1;
        final monday = mondaysInSection[wIdx];
        final weekDesigns = weekGroups[monday]!;
        final weekStartRow = row;
        int weekTotal = 0;
        int weekFinish = 0;

        // Group by received date within the week (for the DATES merge).
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

          // One row per design — RP numbers are never combined.
          for (final d in dayDesigns) {
            final noFinish = d.designMailSendDate != null ? 1 : 0;
            final noPending = 1 - noFinish;

            _setCell(sheet, 2, row, d.customerName ?? '');
            _setCell(sheet, 3, row, 1);
            _setCell(sheet, 4, row, noFinish);
            _setCell(sheet, 5, row, noPending);
            _setCell(sheet, 6, row, d.rpNo ?? '');
            _setCell(sheet, 7, row,
                d.designMailSendDate != null ? _fmt.format(d.designMailSendDate!) : '');
            _setCell(sheet, 8, row, d.designLeadTimeDays,
                background: _leadTimeHighlight);
            _setEmptyableCell(sheet, 9, row, d.cadApprovedDate);
            _setEmptyableCell(sheet, 10, row, d.strikeOffDate);
            _setCell(sheet, 11, row, d.sOffLeadTimeDays,
                background: _leadTimeHighlight);
            _setEmptyableCell(sheet, 12, row, d.rotaryScreenDate);

            weekTotal += 1;
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
        row++;
        row++; // blank spacer row between weeks
      }
      row++; // extra blank row between month sections
    }

    final bytes = excelFile.encode();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/design_tracker_export_$stamp.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Design Tracker - Weekly Report',
      subject: 'Design Tracker Export ($stamp)',
    );
  }

  /// CAD APP MAIL / S/OFF DATE / D ROTARY cells: shows the formatted
  /// date normally, or "-" in red when the stage hasn't happened yet.
  static void _setEmptyableCell(Sheet sheet, int col, int row, DateTime? date) {
    if (date == null) {
      _setCell(sheet, col, row, '-', fontColor: _redFont);
    } else {
      _setCell(sheet, col, row, _fmt.format(date));
    }
  }

  static void _setCell(Sheet sheet, int col, int row, Object? value,
      {bool bold = false, ExcelColor? fontColor, ExcelColor? background}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    if (value == null) {
      cell.value = TextCellValue('');
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }
    cell.cellStyle = CellStyle(
      bold: bold,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: fontColor ?? ExcelColor.black,
      backgroundColorHex: background ?? ExcelColor.none,
    );
  }
}
