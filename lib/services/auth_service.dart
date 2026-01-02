import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print("Error signing in anonymously: $e");
      }
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint("Error signing in: $e");
      rethrow;
    }
  }

  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
        _user = _auth.currentUser;
        notifyListeners();
      }
      return _user;
    } catch (e) {
      debugPrint("Error signing up: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String generateRandomName() {
    final adjectives = [
      'Happy',
      'Lucky',
      'Sunny',
      'Clever',
      'Swift',
      'Brave',
      'Calm',
      'Eager',
      'Kind',
      'Bold',
    ];
    final animals = [
      'Panda',
      'Fox',
      'Tiger',
      'Eagle',
      'Badger',
      'Dolphin',
      'Lion',
      'Wolf',
      'Hawk',
      'Bear',
    ];
    // Simple random selection
    final adj = (adjectives..shuffle()).first;
    final animal = (animals..shuffle()).first;
    return '$adj $animal';
  }
}
