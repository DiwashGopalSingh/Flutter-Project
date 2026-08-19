class CampaignModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final String organizerId;
  final String organizerName;
  final List<String> registeredUserIds;
  final List<String> donatedUserIds;
  final List<String> targetBloodGroups;
  final int targetUnits;
  final bool isActive;

  CampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.organizerId,
    required this.organizerName,
    this.registeredUserIds = const [],
    this.donatedUserIds = const [],
    this.targetBloodGroups = const [],
    this.targetUnits = 50,
    this.isActive = true,
  });

  factory CampaignModel.fromMap(Map<String, dynamic> map, String id) {
    return CampaignModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      organizerId: map['organizerId'] ?? '',
      organizerName: map['organizerName'] ?? '',
      registeredUserIds: List<String>.from(map['registeredUserIds'] ?? []),
      donatedUserIds: List<String>.from(map['donatedUserIds'] ?? []),
      targetBloodGroups: List<String>.from(map['targetBloodGroups'] ?? []),
      targetUnits: map['targetUnits'] ?? 50,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'registeredUserIds': registeredUserIds,
      'donatedUserIds': donatedUserIds,
      'targetBloodGroups': targetBloodGroups,
      'targetUnits': targetUnits,
      'isActive': isActive,
    };
  }

  CampaignModel copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? date,
    List<String>? registeredUserIds,
    List<String>? donatedUserIds,
    List<String>? targetBloodGroups,
    int? targetUnits,
    bool? isActive,
  }) {
    return CampaignModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      organizerId: organizerId,
      organizerName: organizerName,
      registeredUserIds: registeredUserIds ?? this.registeredUserIds,
      donatedUserIds: donatedUserIds ?? this.donatedUserIds,
      targetBloodGroups: targetBloodGroups ?? this.targetBloodGroups,
      targetUnits: targetUnits ?? this.targetUnits,
      isActive: isActive ?? this.isActive,
    );
  }
}
