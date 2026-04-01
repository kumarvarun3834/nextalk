import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  /// ------------------------------
  /// SIGN UP
  /// ------------------------------
  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var user = await _authService.signUp(email, password);
      if (user != null) {
        // Create a new UserModel with UID
        _currentUser = UserModel(
          uid: user.uid,
          email: user.email!,
          name: '',
          bio: '',
          profilePicture: '',
        );

        // Save user in Firestore
        await _firestoreService.createUser(_currentUser!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Sign-Up Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// ------------------------------
  /// LOGIN
  /// ------------------------------
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      var user = await _authService.login(email, password);
      if (user != null) {
        // Fetch user from Firestore
        UserModel? firestoreUser = await _firestoreService.getUser(user.uid);

        // If user exists in Firestore, use it; otherwise create a new UserModel
        _currentUser = firestoreUser ??
            UserModel(
              uid: user.uid,
              email: user.email!,
              name: '',
              bio: '',
              profilePicture: '',
            );

        // If new user, save to Firestore
        if (firestoreUser == null) {
          await _firestoreService.createUser(_currentUser!);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// ------------------------------
  /// LOGOUT
  /// ------------------------------
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// ------------------------------
  /// SET CURRENT USER (after profile setup)
  /// ------------------------------
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}
