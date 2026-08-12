class BloodRequestModel {
  final String id;
  final String requestedBy; // userId
  final String requesterName;
  final String hospitalName;
  final String bloodGroup;
  final int quantity;
  final int fulfilledQuantity;
  final String urgency; // Normal, Urgent, Emergency
  final String status; // Pending, Processing, Fulfilled, Cancelled
  final String? patientName;
  final String? notes;
  final DateTime requestDate;
  final DateTime? fulfilledDate;
  final String contactPhone;

  BloodRequestModel({
    required this.id,
    required this.requestedBy,
    required this.requesterName,
    required this.hospitalName,
    required this.bloodGroup,
    required this.quantity,
    this.fulfilledQuantity = 0,
    required this.urgency,
    required this.status,
    this.patientName,
    this.notes,
    required this.requestDate,
    this.fulfilledDate,
    required this.contactPhone,
  });

  bool get isEmergency => urgency == 'Emergency';
  bool get isUrgent => urgency == 'Urgent';
  bool get isPending => status == 'Pending';
  bool get isFulfilled => status == 'Fulfilled';
  bool get isCancelled => status == 'Cancelled';
  int get remainingQuantity => (quantity - fulfilledQuantity) < 0 ? 0 : (quantity - fulfilledQuantity);

  factory BloodRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return BloodRequestModel(
      id: id,
      requestedBy: map['requestedBy'] ?? '',
      requesterName: map['requesterName'] ?? '',
      hospitalName: map['hospitalName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      quantity: map['quantity'] ?? 1,
      fulfilledQuantity: map['fulfilledQuantity'] ?? 0,
      urgency: map['urgency'] ?? 'Normal',
      status: map['status'] ?? 'Pending',
      patientName: map['patientName'],
      notes: map['notes'],
      requestDate: map['requestDate'] != null
          ? DateTime.tryParse(map['requestDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      fulfilledDate: map['fulfilledDate'] != null
          ? DateTime.tryParse(map['fulfilledDate'].toString())
          : null,
      contactPhone: map['contactPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestedBy': requestedBy,
      'requesterName': requesterName,
      'hospitalName': hospitalName,
      'bloodGroup': bloodGroup,
      'quantity': quantity,
      'fulfilledQuantity': fulfilledQuantity,
      'urgency': urgency,
      'status': status,
      'patientName': patientName,
      'notes': notes,
      'requestDate': requestDate.toIso8601String(),
      'fulfilledDate': fulfilledDate?.toIso8601String(),
      'contactPhone': contactPhone,
    };
  }

  BloodRequestModel copyWith({
    String? status,
    int? fulfilledQuantity,
    DateTime? fulfilledDate,
    String? notes,
  }) {
    return BloodRequestModel(
      id: id,
      requestedBy: requestedBy,
      requesterName: requesterName,
      hospitalName: hospitalName,
      bloodGroup: bloodGroup,
      quantity: quantity,
      fulfilledQuantity: fulfilledQuantity ?? this.fulfilledQuantity,
      urgency: urgency,
      status: status ?? this.status,
      patientName: patientName,
      notes: notes ?? this.notes,
      requestDate: requestDate,
      fulfilledDate: fulfilledDate ?? this.fulfilledDate,
      contactPhone: contactPhone,
    );
  }
}
