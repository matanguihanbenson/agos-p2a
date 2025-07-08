import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class BotDetailsController extends ChangeNotifier {
  final String botId;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  StreamSubscription<DatabaseEvent>? _subscription;
  Map<String, dynamic>? realtimeData;
  bool isAdmin = false;

  BotDetailsController({required this.botId}) {
    _init();
  }

  void _init() {
    _subscribeToRealtime();
    _checkAdmin();
  }

  void _subscribeToRealtime() {
    _subscription = _database.child('bots').child(botId).onValue.listen((
      event,
    ) {
      if (event.snapshot.exists) {
        realtimeData = Map<String, dynamic>.from(event.snapshot.value as Map);
        notifyListeners();
      }
    });
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final role = doc.data()?['role']?.toString().toLowerCase();
    isAdmin = role == 'admin';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
