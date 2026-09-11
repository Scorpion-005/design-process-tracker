import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/design.dart';

class ExportService {
  /// Builds a CSV file from the given designs and opens the share sheet
  /// (WhatsApp, email, drive, etc. all appear as options).
  static Future<void> exportAndShare(List<Design> designs) async {
    final rows = <List<String>>[
      [
        'RP No',
        'Customer Name',
        'Design Name',
        'Received Date',
        'CAD Approved Date',
        'Strike Off Date',
        'Rotary Screen Date',
        'Current Stage',
        'Remarks',
      ],
    ];

    final fmt = DateFormat('dd MMM yyyy');

    for (final d in designs) {
      rows.add([
        d.rpNo ?? '',
        d.customerName ?? '',
        d.name,
        fmt.format(d.receivedDate),
        d.cadApprovedDate != null ? fmt.format(d.cadApprovedDate!) : '',
        d.strikeOffDate != null ? fmt.format(d.strikeOffDate!) : '',
        d.rotaryScreenDate != null ? fmt.format(d.rotaryScreenDate!) : '',
        d.currentStage.label,
        d.remarks ?? '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${dir.path}/design_tracker_export_$stamp.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Design Process Tracker - Export',
      subject: 'Design Tracker Export ($stamp)',
    );
  }
}
