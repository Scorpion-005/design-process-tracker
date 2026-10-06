import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Turns a plain .xlsx (made by the `excel` package) into a macro-enabled
/// .xlsm by embedding `assets/vbaProject.bin`.
///
/// vbaProject.bin carries ThisWorkbook + Module1 code. If that file was saved
/// from Excel with "Lock project for viewing" + a password, the exported
/// workbook asks for the same password before anyone can view or edit the code.
class MacroPackager {
  static const _asset = 'assets/vbaProject.bin';
  static const mimeType = 'application/vnd.ms-excel.sheet.macroEnabled.12';

  static Future<Uint8List> toMacroWorkbook(List<int> xlsxBytes) async {
    final vba = (await rootBundle.load(_asset)).buffer.asUint8List();
    final src = ZipDecoder().decodeBytes(xlsxBytes);
    final out = Archive();

    final sheetRe = RegExp(r'^xl/worksheets/sheet(\d+)\.xml$');

    for (final f in src.files) {
      if (!f.isFile) continue;
      List<int> data = f.content as List<int>;
      final name = f.name;

      if (name == '[Content_Types].xml') {
        data = utf8.encode(_contentTypes(utf8.decode(data)));
      } else if (name == 'xl/_rels/workbook.xml.rels') {
        data = utf8.encode(_workbookRels(utf8.decode(data)));
      } else if (name == 'xl/workbook.xml') {
        data = utf8.encode(_workbookXml(utf8.decode(data)));
      } else {
        final m = sheetRe.firstMatch(name);
        if (m != null) {
          data = utf8.encode(_sheetXml(utf8.decode(data), 'Sheet${m.group(1)}'));
        }
      }
      out.addFile(ArchiveFile(name, data.length, data));
    }

    out.addFile(ArchiveFile('xl/vbaProject.bin', vba.length, vba));

    final encoded = ZipEncoder().encode(out);
    if (encoded == null) {
      throw StateError('Could not build macro workbook');
    }
    return Uint8List.fromList(encoded);
  }

  static String _contentTypes(String xml) {
    xml = xml.replaceAll(
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml',
      'application/vnd.ms-excel.sheet.macroEnabled.main+xml',
    );
    if (!xml.contains('/xl/vbaProject.bin')) {
      xml = xml.replaceFirst(
        '</Types>',
        '<Override PartName="/xl/vbaProject.bin" '
            'ContentType="application/vnd.ms-office.vbaProject"/></Types>',
      );
    }
    return xml;
  }

  static String _workbookRels(String xml) {
    if (xml.contains('vbaProject')) return xml;
    return xml.replaceFirst(
      '</Relationships>',
      '<Relationship Id="rIdVba1" '
          'Type="http://schemas.microsoft.com/office/2006/relationships/vbaProject" '
          'Target="vbaProject.bin"/></Relationships>',
    );
  }

  /// Gives the workbook the code name "ThisWorkbook" so the Workbook_* events
  /// in the VBA project are bound to it.
  static String _workbookXml(String xml) {
    if (xml.contains('codeName=')) return xml;
    final wbPr = RegExp(r'<workbookPr(\s[^>]*?)?(/?)>');
    if (wbPr.hasMatch(xml)) {
      return xml.replaceFirstMapped(wbPr,
          (m) => '<workbookPr${m.group(1) ?? ''} codeName="ThisWorkbook"${m.group(2)}>');
    }
    final fileVersion = RegExp(r'<fileVersion[^>]*/>');
    final fv = fileVersion.firstMatch(xml);
    if (fv != null) {
      return xml.replaceRange(
          fv.end, fv.end, '<workbookPr codeName="ThisWorkbook"/>');
    }
    final open = RegExp(r'<workbook[^>]*>').firstMatch(xml);
    if (open == null) return xml;
    return xml.replaceRange(
        open.end, open.end, '<workbookPr codeName="ThisWorkbook"/>');
  }

  static String _sheetXml(String xml, String codeName) {
    if (xml.contains('codeName=')) return xml;
    final sheetPr = RegExp(r'<sheetPr(\s[^>]*?)?(/?)>');
    if (sheetPr.hasMatch(xml)) {
      return xml.replaceFirstMapped(sheetPr,
          (m) => '<sheetPr${m.group(1) ?? ''} codeName="$codeName"${m.group(2)}>');
    }
    final open = RegExp(r'<worksheet[^>]*>').firstMatch(xml);
    if (open == null) return xml;
    return xml.replaceRange(open.end, open.end, '<sheetPr codeName="$codeName"/>');
  }
}
