import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/design.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('designs');

  Future<String> insertDesign(Design design) async {
    final docRef = await _collection.add(design.toMap());
    return docRef.id;
  }

  Future<void> updateDesign(Design design) async {
    if (design.id == null) return;
    await _collection.doc(design.id).update(design.toMap());
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

  /// Every distinct company name saved so far, for the Company Name
  /// autocomplete on the Add Design screen. Always reflects the latest
  /// data â€” a brand-new company typed and saved today shows up as a
  /// suggestion the next time someone opens this screen.
  Future<List<String>> fetchDistinctCompanyNames() async {
    final snapshot = await _collection.get();
    final names = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['customerName'] as String?)?.trim();
      if (name != null && name.isNotEmpty) names.add(name);
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}
