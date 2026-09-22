import 'package:cloud_firestore/cloud_firestore.dart';

enum DesignStage { received, cadApproved, strikeOff, rotaryScreen }

extension DesignStageX on DesignStage {
  String get label {
    switch (this) {
      case DesignStage.received:
        return 'Design Received';
      case DesignStage.cadApproved:
        return 'CAD / Design Approved';
      case DesignStage.strikeOff:
        return 'Strike Off Finished';
      case DesignStage.rotaryScreen:
        return 'Rotary Screen Printed';
    }
  }
}

class Design {
  final String? id;
  final String? rpNo;
  final String? customerName;
  final String? buyerName;
  final String name;
  final String? remarks;
  final DateTime receivedDate;
  DateTime? designMailSendDate;
  DateTime? cadApprovedDate;
  DateTime? strikeOffDate;
  DateTime? rotaryScreenDate;
  String? cadApprovedBy;
  String? strikeOffBy;
  String? rotaryScreenBy;

  Design({
    this.id,
    this.rpNo,
    this.customerName,
    this.buyerName,
    required this.name,
    this.remarks,
    required this.receivedDate,
    this.designMailSendDate,
    this.cadApprovedDate,
    this.strikeOffDate,
    this.rotaryScreenDate,
    this.cadApprovedBy,
    this.strikeOffBy,
    this.rotaryScreenBy,
  });

  DesignStage get currentStage {
    if (rotaryScreenDate != null) return DesignStage.rotaryScreen;
    if (strikeOffDate != null) return DesignStage.strikeOff;
    if (cadApprovedDate != null) return DesignStage.cadApproved;
    return DesignStage.received;
  }

  int? get daysToStrikeOff {
    if (strikeOffDate == null) return null;
    return strikeOffDate!.difference(receivedDate).inDays;
  }

  /// "DESIGN LEAD TIME" column: days between design received and design
  /// mail send.
  int? get designLeadTimeDays {
    if (designMailSendDate == null) return null;
    return designMailSendDate!.difference(receivedDate).inDays;
  }

  /// "S/OFF LEAD TIME" column: days between CAD app mail and S/OFF date.
  int? get sOffLeadTimeDays {
    if (strikeOffDate == null || cadApprovedDate == null) return null;
    return strikeOffDate!.difference(cadApprovedDate!).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'rpNo': rpNo,
      'customerName': customerName,
      'buyerName': buyerName,
      'name': name,
      'remarks': remarks,
      'receivedDate': receivedDate.toIso8601String(),
      'designMailSendDate': designMailSendDate?.toIso8601String(),
      'cadApprovedDate': cadApprovedDate?.toIso8601String(),
      'strikeOffDate': strikeOffDate?.toIso8601String(),
      'rotaryScreenDate': rotaryScreenDate?.toIso8601String(),
      'cadApprovedBy': cadApprovedBy,
      'strikeOffBy': strikeOffBy,
      'rotaryScreenBy': rotaryScreenBy,
    };
  }

  factory Design.fromMap(Map<String, dynamic> map, String id) {
    return Design(
      id: id,
      rpNo: map['rpNo'] as String?,
      customerName: map['customerName'] as String?,
      buyerName: map['buyerName'] as String?,
      name: map['name'] as String,
      remarks: map['remarks'] as String?,
      receivedDate: DateTime.parse(map['receivedDate'] as String),
      designMailSendDate: map['designMailSendDate'] != null
          ? DateTime.parse(map['designMailSendDate'] as String)
          : null,
      cadApprovedDate: map['cadApprovedDate'] != null
          ? DateTime.parse(map['cadApprovedDate'] as String)
          : null,
      strikeOffDate: map['strikeOffDate'] != null
          ? DateTime.parse(map['strikeOffDate'] as String)
          : null,
      rotaryScreenDate: map['rotaryScreenDate'] != null
          ? DateTime.parse(map['rotaryScreenDate'] as String)
          : null,
      cadApprovedBy: map['cadApprovedBy'] as String?,
      strikeOffBy: map['strikeOffBy'] as String?,
      rotaryScreenBy: map['rotaryScreenBy'] as String?,
    );
  }

  factory Design.fromSnapshot(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Design.fromMap(map, doc.id);
  }

  Design copyWith({
    String? rpNo,
    String? customerName,
    String? buyerName,
    String? name,
    String? remarks,
    DateTime? receivedDate,
    DateTime? designMailSendDate,
    DateTime? cadApprovedDate,
    DateTime? strikeOffDate,
    DateTime? rotaryScreenDate,
    String? cadApprovedBy,
    String? strikeOffBy,
    String? rotaryScreenBy,
  }) {
    return Design(
      id: id,
      rpNo: rpNo ?? this.rpNo,
      customerName: customerName ?? this.customerName,
      buyerName: buyerName ?? this.buyerName,
      name: name ?? this.name,
      remarks: remarks ?? this.remarks,
      receivedDate: receivedDate ?? this.receivedDate,
      designMailSendDate: designMailSendDate ?? this.designMailSendDate,
      cadApprovedDate: cadApprovedDate ?? this.cadApprovedDate,
      strikeOffDate: strikeOffDate ?? this.strikeOffDate,
      rotaryScreenDate: rotaryScreenDate ?? this.rotaryScreenDate,
      cadApprovedBy: cadApprovedBy ?? this.cadApprovedBy,
      strikeOffBy: strikeOffBy ?? this.strikeOffBy,
      rotaryScreenBy: rotaryScreenBy ?? this.rotaryScreenBy,
    );
  }
}
