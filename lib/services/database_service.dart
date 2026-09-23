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
  /// autocomplete on the Add Design screen. This list only grows â€”
  /// deleting a design never removes a company from here.
  Future<List<String>> fetchDistinctCompanyNames() async {
    final snapshot = await _companyCollection.get();
    final names = snapshot.docs
        .map((doc) =>
            (doc.data() as Map<String, dynamic>)['name'] as String?)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  /// Explicitly removes a company from the suggestion list. This is
  /// never called automatically by deleteDesign/updateDesign â€” a company
  /// only disappears from suggestions if this is called on purpose.
  Future<void> deleteCompanyName(String name) async {
    await _companyCollection.doc(name.trim().toUpperCase()).delete();
  }
}
