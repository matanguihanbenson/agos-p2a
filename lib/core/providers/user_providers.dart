import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userRoleProvider = StreamProvider<String>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value('field_operator'); // Default role when not authenticated
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) {
        // Debug print to see when role changes
        final role = (snap.data()?['role'] as String?) ?? 'field_operator';
        print('Role updated to: $role for user: $uid');
        return role;
      })
      .handleError((error) {
        print('Error fetching user role: $error');
        return 'field_operator'; // Fallback role on error
      });
});

// Additional provider for user data if needed
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data());
});
