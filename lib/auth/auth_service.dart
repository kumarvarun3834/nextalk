import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ---------------- CURRENT USER ----------------
  User? get user => _auth.currentUser;

  /// ---------------- SIGN UP ----------------
  Future<User?> signUp(String email, String password) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = res.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.code; // clean error pass
    } catch (e) {
      throw "signup_failed";
    }
  }

  /// ---------------- LOGIN ----------------
  Future<User?> login(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return res.user;
    } on FirebaseAuthException catch (e) {
      throw e.code;
    } catch (e) {
      throw "login_failed";
    }
  }

  /// ---------------- CHECK EMAIL VERIFIED ----------------
  Future<bool> isEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  /// ---------------- RESEND VERIFICATION ----------------
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) throw "no_user";

    try {
      await user.sendEmailVerification();
    } catch (e) {
      throw "resend_failed";
    }
  }

  /// ---------------- RELOAD USER ----------------
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw "reload_failed";
    }
  }

  /// ---------------- LOGOUT ----------------
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw "logout_failed";
    }
  }
}