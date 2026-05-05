import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthUser {
  final String uid;
  final String name;
  final String email;

  const AuthUser({required this.uid, required this.name, required this.email});

  factory AuthUser.fromFirebase(User firebaseUser, [Map<String, dynamic>? extraData]) => AuthUser(
        uid: firebaseUser.uid,
        name: extraData?['name'] ?? firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
      );
}

class AuthProvider extends ChangeNotifier {
  AuthUser? _user;
  bool _initialized = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        // Fetch extra data from Firestore
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        _user = AuthUser.fromFirebase(firebaseUser, doc.data());
      } else {
        _user = null;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
