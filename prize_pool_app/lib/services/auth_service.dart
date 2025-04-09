import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import 'database_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Flag to indicate if we're in demo mode (no Firebase)
  // Set this to false when using real Firebase
  final bool _demoMode = false;

  // Auth state
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Constructor
  AuthService() {
    _init();
  }

  // Initialize auth state
  void _init() {
    if (_demoMode) {
      // In demo mode, we'll create a demo user
      _user = UserModel(
        uid: 'demo-user-id',
        email: 'demo@example.com',
        username: 'Demo User',
        adWatchCount: 5,
        earnings: 2.50,
        lastAdWatchTime: DateTime.now().subtract(const Duration(days: 2)),
      );
      notifyListeners();
    } else {
      // In Firebase mode, listen to auth state changes
      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _user = null;
        } else {
          _user = await _databaseService.getUser(firebaseUser.uid);

          // If user doesn't exist in Firestore yet, create it
          if (_user == null) {
            final newUser = UserModel(
              uid: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              username:
                  firebaseUser.displayName ??
                  firebaseUser.email?.split('@')[0] ??
                  'User',
            );
            await _databaseService.createUser(newUser);
            _user = newUser;
          }
        }
        notifyListeners();
      });
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        // In demo mode, accept any email/password
        _user = UserModel(
          uid: 'demo-user-id',
          email: email,
          username: email.split('@')[0],
          adWatchCount: 5,
          earnings: 2.50,
          lastAdWatchTime: DateTime.now().subtract(const Duration(days: 2)),
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // In Firebase mode, use Firebase Authentication
        final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        _isLoading = false;
        notifyListeners();
        return result.user != null;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        // Create user in demo mode
        final UserModel newUser = UserModel(
          uid: 'demo-user-id',
          email: email,
          username: username,
          adWatchCount: 0,
          earnings: 0.0,
          lastAdWatchTime: DateTime.now(),
        );

        // In a real app, we would save to Firestore here
        _user = newUser;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // In Firebase mode, use Firebase Authentication
        final UserCredential result = await _auth
            .createUserWithEmailAndPassword(email: email, password: password);

        if (result.user != null) {
          // Create user in Firestore
          final UserModel newUser = UserModel(
            uid: result.user!.uid,
            email: email,
            username: username,
          );

          await _databaseService.createUser(newUser);
          _user = newUser;
        }

        _isLoading = false;
        notifyListeners();
        return result.user != null;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (_demoMode) {
        // In demo mode, just clear the user
        _user = null;
        notifyListeners();
        return;
      } else {
        // In Firebase mode, use Firebase Authentication
        await _auth.signOut();
        _user = null;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_demoMode) {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));

        // In demo mode, just pretend we sent a reset email
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // In Firebase mode, use Firebase Authentication
        await _auth.sendPasswordResetEmail(email: email);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
