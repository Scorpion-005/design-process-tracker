import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/design.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('designs');

  // Permanent list of every company name ever entered. Kept separate
  // from the designs collection on purpose: deleting a design (or every
  // design belonging to a company) must NOT remove that company from
  // the Company Name autocomplete suggestions.
  final CollectionReference _companyCollection =
      FirebaseFirestore.instance.collection('company_names');

  Future<String> insertDesign(Design design) async {
    final normalized = _normalizeCompanyName(design);
    if (normalized.customerName != null) {
      await saveCompanyName(normalized.customerName!);
    }
    final docRef = await _collection.add(normalized.toMap());
    return docRef.id;
  }

  Future<void> updateDesign(Design design) async {
    if (design.id == null) return;
    final normalized = _normalizeCompanyName(design);
    if (normalized.customerName != null) {
      await saveCompanyName(normalized.customerName!);
    }
    await _collection.doc(design.id).update(normalized.toMap());
  }

  /// Always stores the company name in UPPERCASE, no matter how it was
  /// typed, so "spike creation" and "SPIKE CREATION" are always treated
  /// as the exact same company â€” no duplicate entries.
  Design _normalizeCompanyName(Design design) {
    final trimmed = design.customerName?.trim();
    if (trimmed == null || trimmed.isEmpty) return design;
    return design.copyWith(customerName: trimmed.toUpperCase());
  }

  Future<void> deleteDesign(String id) async {
    await _collection.doc(id).delete();
  }

  Future<List<Design>> getAllDesigns() async {
    final snapshot =
        await _collection.orderBy('receivedDate', descending: true).get();
    return snapshot.docs.map((doc) => Design.fromSnapshot(doc)).toList();
  }

  /// Real-time stream of all designs, ordered by received date descending.
  Stream<List<Design>> watchAllDesigns() {
    return _collection
        .orderBy('receivedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Design.fromSnapshot(doc)).toList());
  }

  Future<Design?> getDesign(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Design.fromSnapshot(doc);
  }

  Future<List<Design>> getDesignsReceivedOn(DateTime day) =>
      _filterByDateField('receivedDate', day);

  Future<List<Design>> getDesignsApprovedOn(DateTime day) =>
      _filterByDateField('cadApprovedDate', day);

  Future<List<Design>> getDesignsStrikeOffOn(DateTime day) =>
      _filterByDateField('strikeOffDate', day);

  Future<List<Design>> getDesignsRotaryOn(DateTime day) =>
      _filterByDateField('rotaryScreenDate', day);

  Future<List<Design>> _filterByDateField(String field, DateTime day) async {
    final all = await getAllDesigns();
    return all.where((d) {
      DateTime? value;
      switch (field) {
        case 'receivedDate':
          value = d.receivedDate;
          break;
        case 'cadApprovedDate':
          value = d.cadApprovedDate;
          break;
        case 'strikeOffDate':
          value = d.strikeOffDate;
          break;
        case 'rotaryScreenDate':
          value = d.rotaryScreenDate;
          break;
      }
      if (value == null) return false;
      return value.year == day.year &&
          value.month == day.month &&
          value.day == day.day;
    }).toList();
  }

  /// Adds [name] (UPPERCASED) to the permanent company list. Using the
  /// uppercased name itself as the document id means saving the same
  /// company twice is a harmless no-op â€” duplicates can never happen.
  Future<void> saveCompanyName(String name) async {
    final upper = name.trim().toUpperCase();
    if (upper.isEmpty) return;
    await _companyCollection.doc(upper).set({'name': upper});
  }

  /// Every distinct company name ever saved, for the Company Name
  /// autocomplete on the Add Design screen. Combines two sources so
  /// nothing gets lost:
  ///  1. The permanent company_names list â€” grows forever, survives
  ///     design deletions.
  ///  2. Company names already sitting on existing designs (from before
  ///     this permanent list existed) â€” kept here so old data still
  ///     shows up as suggestions too.
  Future<List<String>> fetchDistinctCompanyNames() async {
    final names = <String>{};

    final companySnapshot = await _companyCollection.get();
    for (final doc in companySnapshot.docs) {
      final name = (doc.data() as Map<String, dynamic>)['name'] as String?;
      if (name != null && name.trim().isNotEmpty) names.add(name.trim());
    }

    final designSnapshot = await _collection.get();
    for (final doc in designSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['customerName'] as String?)?.trim();
      if (raw != null && raw.isNotEmpty) {
        final upper = raw.toUpperCase();
        names.add(upper);
        // Backfill this old name into the permanent list so next time
        // it comes only from there, and survives if this design is
        // ever deleted.
        unawaited(saveCompanyName(upper));
      }
    }

    final list = names.toList()..sort();
    return list;
  }

  /// Explicitly removes a company from the suggestion list. This is
  /// never called automatically by deleteDesign/updateDesign â€” a company
  /// only disappears from suggestions if this is called on purpose.
  Future<void> deleteCompanyName(String name) async {
    await _companyCollection.doc(name.trim().toUpperCase()).delete();
  }
}
