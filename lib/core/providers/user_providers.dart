import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider that watches auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Provider that provides the current user's role, automatically updating when user changes
final userRoleProvider = StreamProvider<String>((ref) {
  // Watch the auth state to get current user
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        print('No user authenticated - returning default role');
        return Stream.value('field_operator');
      }

      print('User authenticated: ${user.uid} - fetching role');
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) {
            final role = (snap.data()?['role'] as String?) ?? 'field_operator';
            print('Role updated to: $role for user: ${user.uid}');
            return role;
          })
          .handleError((error) {
            print('Error fetching user role: $error');
            return 'field_operator';
          });
    },
    loading: () => Stream.value('field_operator'),
    error: (error, stack) {
      print('Auth state error: $error');
      return Stream.value('field_operator');
    },
  );
});

// Provider for current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user?.uid,
    loading: () => null,
    error: (error, stack) => null,
  );
});

// Additional provider for user data if needed
final userDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) => snap.data());
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});

// Provider to get the admin who created the current user (for field operators)
final createdByAdminProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snap) {
            final data = snap.data();
            if (data == null) return null;

            // Return the admin ID who created this user
            return data['created_by_admin'] as String?;
          });
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});
