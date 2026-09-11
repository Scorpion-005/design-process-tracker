enum DesignStage { received, cadApproved, strikeOff, rotaryScreen }

extension DesignStageX on DesignStage {
  String get label {
    switch (this) {
      case DesignStage.received:
        return 'Design Received';
      case DesignStage.cadApproved:
        return 'CAD / Design Approved';
      case DesignStage.strikeOff:
        return 'Strike Off Given';
      case DesignStage.rotaryScreen:
        return 'Rotary Screen Printed';
    }
  }
}

class Design {
  final int? id;
  final String? rpNo;
  final String? customerName;
  final String? buyerName;
  final String name;
  final String? remarks;
  final DateTime receivedDate;
  DateTime? cadApprovedDate;
  DateTime? strikeOffDate;
  DateTime? rotaryScreenDate;

  Design({
    this.id,
    this.rpNo,
    this.customerName,
    this.buyerName,
    required this.name,
    this.remarks,
    required this.receivedDate,
    this.cadApprovedDate,
    this.strikeOffDate,
    this.rotaryScreenDate,
  });

  DesignStage get currentStage {
    if (rotaryScreenDate != null) return DesignStage.rotaryScreen;
    if (strikeOffDate != null) return DesignStage.strikeOff;
    if (cadApprovedDate != null) return DesignStage.cadApproved;
    return DesignStage.received;
  }

  /// Days elapsed between received date and strike off date, if set.
  int? get daysToStrikeOff {
    if (strikeOffDate == null) return null;
    return strikeOffDate!.difference(receivedDate).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rpNo': rpNo,
      'customerName': customerName,
      'buyerName': buyerName,
      'name': name,
      'remarks': remarks,
      'receivedDate': receivedDate.toIso8601String(),
      'cadApprovedDate': cadApprovedDate?.toIso8601String(),
      'strikeOffDate': strikeOffDate?.toIso8601String(),
      'rotaryScreenDate': rotaryScreenDate?.toIso8601String(),
    };
  }

  factory Design.fromMap(Map<String, dynamic> map) {
    return Design(
      id: map['id'] as int?,
      rpNo: map['rpNo'] as String?,
      customerName: map['customerName'] as String?,
      buyerName: map['buyerName'] as String?,
      name: map['name'] as String,
      remarks: map['remarks'] as String?,
      receivedDate: DateTime.parse(map['receivedDate'] as String),
      cadApprovedDate: map['cadApprovedDate'] != null
          ? DateTime.parse(map['cadApprovedDate'] as String)
          : null,
      strikeOffDate: map['strikeOffDate'] != null
          ? DateTime.parse(map['strikeOffDate'] as String)
          : null,
      rotaryScreenDate: map['rotaryScreenDate'] != null
          ? DateTime.parse(map['rotaryScreenDate'] as String)
          : null,
    );
  }

  Design copyWith({
    String? rpNo,
    String? customerName,
    String? buyerName,
    String? name,
    String? remarks,
    DateTime? receivedDate,
    DateTime? cadApprovedDate,
    DateTime? strikeOffDate,
    DateTime? rotaryScreenDate,
  }) {
    return Design(
      id: id,
      rpNo: rpNo ?? this.rpNo,
      customerName: customerName ?? this.customerName,
      buyerName: buyerName ?? this.buyerName,
      name: name ?? this.name,
      remarks: remarks ?? this.remarks,
      receivedDate: receivedDate ?? this.receivedDate,
      cadApprovedDate: cadApprovedDate ?? this.cadApprovedDate,
      strikeOffDate: strikeOffDate ?? this.strikeOffDate,
      rotaryScreenDate: rotaryScreenDate ?? this.rotaryScreenDate,
    );
  }
}
