import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String email;
  final String firstname;
  final String lastname;
  final bool isActive;
  final String organization;
  final String role;
  final String createdByAdmin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.isActive,
    required this.organization,
    required this.role,
    required this.createdByAdmin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      email: data['email'] ?? '',
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      isActive: data['isActive'] ?? false,
      organization: data['organization'] ?? '',
      role: data['role'] ?? '',
      createdByAdmin: data['created_by_admin'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  String get fullName => '$firstname $lastname'.trim();
  String get initials {
    if (firstname.isNotEmpty && lastname.isNotEmpty) {
      return '${firstname[0]}${lastname[0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : 'U';
  }
}
