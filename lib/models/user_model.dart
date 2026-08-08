enum UserRole { donor, hospital, admin }

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.donor: return 'Donor';
      case UserRole.hospital: return 'Hospital';
      case UserRole.admin: return 'Admin';
    }
  }

  String get value {
    switch (this) {
      case UserRole.donor: return 'donor';
      case UserRole.hospital: return 'hospital';
      case UserRole.admin: return 'admin';
    }
  }

  static UserRole fromString(String role) {
    switch (role) {
      case 'admin': return UserRole.admin;
      case 'hospital': return UserRole.hospital;
      default: return UserRole.donor;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? bloodGroup;
  final String? photoUrl;
  final String? address;
  final String? hospitalName; // for hospital role
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.bloodGroup,
    this.photoUrl,
    this.address,
    this.hospitalName,
    required this.createdAt,
    this.isActive = true,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRoleExtension.fromString(map['role'] ?? 'donor'),
      bloodGroup: map['bloodGroup'],
      photoUrl: map['photoUrl'],
      address: map['address'],
      hospitalName: map['hospitalName'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'bloodGroup': bloodGroup,
      'photoUrl': photoUrl,
      'address': address,
      'hospitalName': hospitalName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? photoUrl,
    String? address,
    String? hospitalName,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      photoUrl: photoUrl ?? this.photoUrl,
      address: address ?? this.address,
      hospitalName: hospitalName ?? this.hospitalName,
      createdAt: createdAt,
      isActive: isActive,
    );
  }
}
