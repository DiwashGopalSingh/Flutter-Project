class AppointmentModel {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodGroup;
  final DateTime appointmentDate;
  final String timeSlot;
  final String location;
  final String status; // Scheduled, Completed, Cancelled, NoShow
  final String? notes;

  AppointmentModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodGroup,
    required this.appointmentDate,
    required this.timeSlot,
    required this.location,
    required this.status,
    this.notes,
  });

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) && status == 'Scheduled';
  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      donorId: map['donorId'] ?? '',
      donorName: map['donorName'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      appointmentDate: map['appointmentDate'] != null
          ? DateTime.tryParse(map['appointmentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'Scheduled',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'bloodGroup': bloodGroup,
      'appointmentDate': appointmentDate.toIso8601String(),
      'timeSlot': timeSlot,
      'location': location,
      'status': status,
      'notes': notes,
    };
  }

  AppointmentModel copyWith({String? status, String? notes}) {
    return AppointmentModel(
      id: id,
      donorId: donorId,
      donorName: donorName,
      bloodGroup: bloodGroup,
      appointmentDate: appointmentDate,
      timeSlot: timeSlot,
      location: location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
