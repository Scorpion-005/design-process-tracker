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
  /// as the exact same company — no duplicate entries.
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

  // One-time seed list: existing company folder names, entered here so
  // they show up as suggestions immediately even before any new design
  // references them. Once added to the permanent list below, this const
  // list is never needed again — it just seeds it on first run.
  static const List<String> _seedCompanyNames = [
    'NAVAGIRI EXPORTS',
    'SCM GARMENTS PVT LTD',
    'SP APPARELS',
    'KAYTEE CORPORATION',
    'KPR SUGAR AND APPARELS LIMITED',
    'SRI COTTON KNITS',
    'MORNING STAAR',
    'SHAKTHI KNITTING',
    'SYNERGY CLOTHING COMPANY',
    'FUSION TENIM & CO',
    'RPK',
    'S.ARADHANA KNITTING MILLS',
    'CENTURY APPARELS',
    'ELITE CLOTHING COMPANY',
    'KITEX GARMENTS',
    'WHITE HOUSE',
    'KM 3',
    'VKN FABRIC',
    'KANNIAMMAN EXPORTS (ESSEN)',
    'KM 1',
    'DEEKAY',
    'J G HOSIERY (P) LTD',
    'GAINUP',
    'MONEY APPARELS',
    'HERO FASHION',
    'S.V. KNITS',
    'FASHION CREATOR',
    'JAY JAY MILLS',
    'KM 2',
    'JVC GARMENTS',
    'BLUE BREEZE',
    'THAI POLYESTER CO.LTD',
    'ESSA GARMENTS',
    'POPPYS KNIT WEAR',
    'SIVAKAMI DESIGNERS',
    'GRASS GREEN CLOTHING',
    'AV FASHION',
    'POLESTER GARMENTS',
    'KUMARAGIRI SPINNERSS (P) LIMITED',
    'ORIGINAL KNIT EXPORTS',
    'DHIKKSHA EXPORTS',
    'AVISH FASHION PVT LTD',
    'KANISKA GARMENTS',
    'QUANTUM 3',
    'SPIKE CREATION',
    'COTTON BLOSSOM',
    'ISWARYA KNIT FABS',
    'JVC FABRIC SALES',
    'SNQS',
    'BALU EXPORTS',
    'VICTORIAN GLOBAL CLOTHING',
    'VEECEE EXPORTS',
    'SRI ANURAGAVI GARMENTS',
    'SKL EXPORTS',
    'KM 7',
    'VISHNU CLOTHING',
    'KM 4',
    'TJ APPARELS',
    'ESA CLOTHING COMPANY (JUBILEE)',
    'AKRUTHI APPARELS',
    'KM 9',
    'GREETINGS KNIT WEARS',
    'UNISOURCE',
    'HONEYWELL CREATION',
    'INDIAN STITCHES PVT LTD',
    'JAYAKUMARAN EXPORTS',
    'KM 14',
    'AISHWARYA FABRICS',
    'JKR FABRICKS',
    'TECHNO SPORTS',
    'KM HO',
    'GUS CLOTHING',
    'KM 11',
    'TRICO GLOBAL TRADES',
  ];

  /// Adds [name] (UPPERCASED) to the permanent company list. Using the
  /// uppercased name itself as the document id means saving the same
  /// company twice is a harmless no-op — duplicates can never happen.
  Future<void> saveCompanyName(String name) async {
    final upper = name.trim().toUpperCase();
    if (upper.isEmpty) return;
    await _companyCollection.doc(upper).set({'name': upper});
  }

  /// Every distinct company name ever saved, for the Company Name
  /// autocomplete on the Add Design screen. Combines three sources so
  /// nothing gets lost:
  ///  1. The permanent company_names list — grows forever, survives
  ///     design deletions.
  ///  2. Company names already sitting on existing designs (from before
  ///     this permanent list existed) — kept here so old data still
  ///     shows up as suggestions too.
  ///  3. The one-time seed list above — any name from it that isn't in
  ///     the permanent list yet gets written there, so this only ever
  ///     runs once per name.
  Future<List<String>> fetchDistinctCompanyNames() async {
    final names = <String>{};

    final companySnapshot = await _companyCollection.get();
    final existingUpper = <String>{};
    for (final doc in companySnapshot.docs) {
      final name = (doc.data() as Map<String, dynamic>)['name'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        final upper = name.trim().toUpperCase();
        names.add(upper);
        existingUpper.add(upper);
      }
    }

    final designSnapshot = await _collection.get();
    for (final doc in designSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = (data['customerName'] as String?)?.trim();
      if (raw != null && raw.isNotEmpty) {
        final upper = raw.toUpperCase();
        names.add(upper);
        if (!existingUpper.contains(upper)) {
          // Backfill this old name into the permanent list so next time
          // it comes only from there, and survives if this design is
          // ever deleted.
          existingUpper.add(upper);
          unawaited(saveCompanyName(upper));
        }
      }
    }

    for (final seed in _seedCompanyNames) {
      final upper = seed.trim().toUpperCase();
      names.add(upper);
      if (!existingUpper.contains(upper)) {
        existingUpper.add(upper);
        unawaited(saveCompanyName(upper));
      }
    }

    final list = names.toList()..sort();
    return list;
  }

  /// Explicitly removes a company from the suggestion list. This is
  /// never called automatically by deleteDesign/updateDesign — a company
  /// only disappears from suggestions if this is called on purpose.
  Future<void> deleteCompanyName(String name) async {
    await _companyCollection.doc(name.trim().toUpperCase()).delete();
  }
}
