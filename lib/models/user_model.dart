import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/enums.dart';

class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String organizationName;
  final String? profileImageUrl;
  final double? latitude;
  final double? longitude;
  final VerificationStatus verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.organizationName,
    this.profileImageUrl,
    this.latitude,
    this.longitude,
    required this.verificationStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String documentId) {
    return UserProfile(
      userId: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: UserRole.fromString(map['role']),
      organizationName: map['organizationName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      verificationStatus: VerificationStatus.fromString(
        map['verificationStatus'],
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'organizationName': organizationName,
      'profileImageUrl': profileImageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'verificationStatus': verificationStatus.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? organizationName,
    String? profileImageUrl,
    double? latitude,
    double? longitude,
    VerificationStatus? verificationStatus,
  }) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      organizationName: organizationName ?? this.organizationName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// Alias for backward compatibility if referenced as UserModel elsewhere
typedef UserModel = UserProfile;
