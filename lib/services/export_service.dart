import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/design.dart';

class ExportService {
  static final _fmt = DateFormat('dd-MM-yyyy');

  static final _leadTimeHighlight = ExcelColor.fromHexString('#FFE699');
  static final _headerFill = ExcelColor.fromHexString('#D9D2E9');
  static final _redFont = ExcelColor.fromHexString('#FF0000');

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
  /// If CAD APP MAIL, S/OFF DATE, or D ROTARY is empty for a design,
  /// that design's entire row is shown in red text so incomplete rows
  /// stand out at a glance.
  static Future<void> exportAndShare(List<Design> designs) async {
    final excelFile = Excel.createExcel();
    final sheetName = excelFile.getDefaultSheet() ?? 'Sheet1';
    final sheet = excelFile[sheetName];

    final colMaxLen = <int, int>{};

    final sorted = List<Design>.from(designs)
      ..sort((a, b) {
        final byDate = a.receivedDate.compareTo(b.receivedDate);
        if (byDate != 0) return byDate;
        final byCustomer =
            (a.customerName ?? '').compareTo(b.customerName ?? '');
        if (byCustomer != 0) return byCustomer;
        return (a.rpNo ?? '').compareTo(b.rpNo ?? '');
      });

    final weekOrder = <DateTime>[];
    final weekGroups = <DateTime, List<Design>>{};
    for (final d in sorted) {
      final monday = _mondayOf(d.receivedDate);
      if (!weekGroups.containsKey(monday)) {
        weekGroups[monday] = [];
        weekOrder.add(monday);
      }
      weekGroups[monday]!.add(d);
    }

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
          bold: true, colMaxLen: colMaxLen);
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: row),
      );
      sheet.setRowHeight(row, 22);
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
            background: isLeadTimeCol ? _leadTimeHighlight : _headerFill,
            colMaxLen: colMaxLen);
      }
      sheet.setRowHeight(row, 32);
      row++;

      for (int wIdx = 0; wIdx < mondaysInSection.length; wIdx++) {
        final weekNum = wIdx + 1;
        final monday = mondaysInSection[wIdx];
        final weekDesigns = weekGroups[monday]!;
        final weekStartRow = row;
        int weekTotal = 0;
        int weekFinish = 0;

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

            // If CAD App Mail, S/OFF Date, or D Rotary is missing,
            // the whole row's text is shown in red.
            final incomplete = d.cadApprovedDate == null ||
                d.strikeOffDate == null ||
                d.rotaryScreenDate == null;
            final rowFont = incomplete ? _redFont : null;

            _setCell(sheet, 2, row, d.customerName ?? '',
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 3, row, 1, fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 4, row, noFinish,
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 5, row, noPending,
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 6, row, d.rpNo ?? '',
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(
                sheet,
                7,
                row,
                d.designMailSendDate != null
                    ? _fmt.format(d.designMailSendDate!)
                    : '',
                fontColor: rowFont,
                colMaxLen: colMaxLen);
            _setCell(sheet, 8, row, d.designLeadTimeDays,
                fontColor: rowFont,
                background: _leadTimeHighlight,
                colMaxLen: colMaxLen);
            _setCell(sheet, 9, row,
                d.cadApprovedDate != null ? _fmt.format(d.cadApprovedDate!) : '-',
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 10, row,
                d.strikeOffDate != null ? _fmt.format(d.strikeOffDate!) : '-',
                fontColor: rowFont, colMaxLen: colMaxLen);
            _setCell(sheet, 11, row, d.sOffLeadTimeDays,
                fontColor: rowFont,
                background: _leadTimeHighlight,
                colMaxLen: colMaxLen);
            _setCell(
                sheet,
                12,
                row,
                d.rotaryScreenDate != null
                    ? _fmt.format(d.rotaryScreenDate!)
                    : '-',
                fontColor: rowFont,
                colMaxLen: colMaxLen);

            sheet.setRowHeight(row, 20);
            weekTotal += 1;
            weekFinish += noFinish;
            row++;
          }

          final dateEndRow = row - 1;
          _setCell(sheet, 1, dateStartRow, _fmt.format(day), colMaxLen: colMaxLen);
          if (dateEndRow > dateStartRow) {
            sheet.merge(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dateStartRow),
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: dateEndRow),
            );
          }
        }

        final weekEndRow = row - 1;
        _setCell(sheet, 0, weekStartRow, 'WEEK $weekNum', colMaxLen: colMaxLen);
        if (weekEndRow > weekStartRow) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: weekStartRow),
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: weekEndRow),
          );
        }

        final weekPending = weekTotal - weekFinish;
        _setCell(sheet, 2, row, "WEEK $weekNum TOTAL DESIGN'S=",
            bold: true, colMaxLen: colMaxLen);
        _setCell(sheet, 3, row, weekTotal, bold: true, colMaxLen: colMaxLen);
        _setCell(sheet, 4, row, weekFinish, bold: true, colMaxLen: colMaxLen);
        _setCell(sheet, 5, row, weekPending, bold: true, colMaxLen: colMaxLen);
        sheet.setRowHeight(row, 20);
        row++;
        row++;
      }
      row++;
    }

    colMaxLen.forEach((col, maxLen) {
      final width = (maxLen * 1.15 + 2).clamp(10.0, 42.0);
      sheet.setColumnWidth(col, width);
    });

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

  static void _setCell(Sheet sheet, int col, int row, Object? value,
      {bool bold = false,
      ExcelColor? fontColor,
      ExcelColor? background,
      Map<int, int>? colMaxLen}) {
    final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    final text = value?.toString() ?? '';
    if (value == null) {
      cell.value = TextCellValue('');
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else {
      cell.value = TextCellValue(text);
    }
    cell.cellStyle = CellStyle(
      bold: bold,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontColorHex: fontColor ?? ExcelColor.black,
      backgroundColorHex: background ?? ExcelColor.none,
    );

    if (colMaxLen != null) {
      final len = text.length + (bold ? 2 : 0);
      final current = colMaxLen[col] ?? 0;
      if (len > current) colMaxLen[col] = len;
    }
  }
}
