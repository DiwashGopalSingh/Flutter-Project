class BloodUnitModel {
  final String id;
  final String bloodGroup;
  final int quantity; // units (1 unit ≈ 450 ml)
  final DateTime collectionDate;
  final DateTime expiryDate;
  final String status; // Available, Reserved, Expired, Used
  final String donorId;
  final String donorName;
  final String location;

  BloodUnitModel({
    required this.id,
    required this.bloodGroup,
    required this.quantity,
    required this.collectionDate,
    required this.expiryDate,
    required this.status,
    required this.donorId,
    required this.donorName,
    required this.location,
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);
  bool get isExpiringSoon =>
      !isExpired && expiryDate.difference(DateTime.now()).inDays <= 7;
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;
  bool get isAvailable => status == 'Available' && !isExpired;

  factory BloodUnitModel.fromMap(Map<String, dynamic> map, String id) {
    return BloodUnitModel(
      id: id,
      bloodGroup: map['bloodGroup'] ?? '',
      quantity: map['quantity'] ?? 0,
      collectionDate: map['collectionDate'] != null
          ? DateTime.tryParse(map['collectionDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.tryParse(map['expiryDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] ?? 'Available',
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      location: map['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bloodGroup': bloodGroup,
      'quantity': quantity,
      'collectionDate': collectionDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'status': status,
      'donorId': donorId,
      'donorName': donorName,
      'location': location,
    };
  }

  BloodUnitModel copyWith({
    String? bloodGroup,
    int? quantity,
    DateTime? collectionDate,
    DateTime? expiryDate,
    String? status,
    String? location,
  }) {
    return BloodUnitModel(
      id: id,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      quantity: quantity ?? this.quantity,
      collectionDate: collectionDate ?? this.collectionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      status: status ?? this.status,
      donorId: donorId,
      donorName: donorName,
      location: location ?? this.location,
    );
  }
}
