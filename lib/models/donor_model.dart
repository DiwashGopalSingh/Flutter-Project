class DonorModel {
  final String id;
  final String userId;
  final String name;
  final String bloodGroup;
  final String phone;
  final String? address;
  final DateTime? lastDonationDate;
  final int totalDonations;
  final List<String> donationIds;
  final bool isEligible;
  final bool isAvailable; // willing to donate now

  DonorModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.bloodGroup,
    required this.phone,
    this.address,
    this.lastDonationDate,
    this.totalDonations = 0,
    this.donationIds = const [],
    this.isEligible = true,
    this.isAvailable = true,
  });

  /// Days remaining before eligible to donate again (56-day rule)
  int get daysUntilEligible {
    if (lastDonationDate == null) return 0;
    final nextDate = lastDonationDate!.add(const Duration(days: 56));
    final diff = nextDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  bool get canDonateNow => daysUntilEligible == 0;

  factory DonorModel.fromMap(Map<String, dynamic> map, String id) {
    return DonorModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'],
      lastDonationDate: map['lastDonationDate'] != null
          ? DateTime.tryParse(map['lastDonationDate'].toString())
          : null,
      totalDonations: map['totalDonations'] ?? 0,
      donationIds: List<String>.from(map['donationIds'] ?? []),
      isEligible: map['isEligible'] ?? true,
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'bloodGroup': bloodGroup,
      'phone': phone,
      'address': address,
      'lastDonationDate': lastDonationDate?.toIso8601String(),
      'totalDonations': totalDonations,
      'donationIds': donationIds,
      'isEligible': isEligible,
      'isAvailable': isAvailable,
    };
  }

  DonorModel copyWith({
    String? address,
    DateTime? lastDonationDate,
    int? totalDonations,
    List<String>? donationIds,
    bool? isEligible,
    bool? isAvailable,
  }) {
    return DonorModel(
      id: id,
      userId: userId,
      name: name,
      bloodGroup: bloodGroup,
      phone: phone,
      address: address ?? this.address,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      totalDonations: totalDonations ?? this.totalDonations,
      donationIds: donationIds ?? this.donationIds,
      isEligible: isEligible ?? this.isEligible,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
