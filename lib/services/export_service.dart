import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/design.dart';
import 'week_utils.dart';

class ExportService {
  /// Builds an Excel (.xlsx) file from the given designs and opens the
  /// share sheet (WhatsApp, email, drive, etc.).
  static Future<void> exportAndShare(List<Design> designs) async {
    final excelFile = Excel.createExcel();
    final sheetName = excelFile.getDefaultSheet() ?? 'Sheet1';
    final sheet = excelFile[sheetName];

    final fmt = DateFormat('dd MMM yyyy');

    final headers = [
      'RP No',
      'Customer Name',
      'Buyer',
      'Design Name',
      'Week',
      'Received Date',
      'CAD Approved Date',
      'Strike Off Date',
      'Rotary Screen Date',
      'Days to Strike Off',
      'Current Stage',
    ];

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    int strikeOffCount = 0;
    int rotaryCount = 0;

    for (final d in designs) {
      if (d.strikeOffDate != null) strikeOffCount++;
      if (d.rotaryScreenDate != null) rotaryCount++;

      sheet.appendRow([
        TextCellValue(d.rpNo ?? ''),
        TextCellValue(d.customerName ?? ''),
        TextCellValue(d.buyerName ?? ''),
        TextCellValue(d.name),
        TextCellValue(WeekUtils.weekLabel(d.receivedDate)),
        TextCellValue(fmt.format(d.receivedDate)),
        TextCellValue(
            d.cadApprovedDate != null ? fmt.format(d.cadApprovedDate!) : ''),
        TextCellValue(
            d.strikeOffDate != null ? fmt.format(d.strikeOffDate!) : ''),
        TextCellValue(d.rotaryScreenDate != null
            ? fmt.format(d.rotaryScreenDate!)
            : ''),
        d.daysToStrikeOff != null
            ? IntCellValue(d.daysToStrikeOff!)
            : TextCellValue(''),
        TextCellValue(d.currentStage.label),
      ]);
    }

    // Enable filter dropdown on the header row (columns A..K).
    if (designs.isNotEmpty) {
      const lastColLetter = 'K'; // 11 header columns: A..K
      sheet.setAutoFilter('A1:$lastColLetter${designs.length + 1}');
    }

    // Blank spacer row, then summary.
    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('No. of Designs Received'),
      IntCellValue(designs.length),
    ]);
    sheet.appendRow([
      TextCellValue('Designs Strike Off Completed'),
      IntCellValue(strikeOffCount),
    ]);
    sheet.appendRow([
      TextCellValue('Designs Rotary Screen Completed'),
      IntCellValue(rotaryCount),
    ]);

    final bytes = excelFile.encode();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/design_tracker_export_$stamp.xlsx');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Design Process Tracker - Export',
      subject: 'Design Tracker Export ($stamp)',
    );
  }
}
