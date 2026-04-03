import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/helpers.dart';

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  // final AuthService auth = AuthService();
  // final FirestoreService firestore = FirestoreService();

  bool loading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    /// 🔁 Auto check every 4 seconds
    _timer = Timer.periodic(Duration(seconds: 4), (_) {
      checkVerification(auto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// ---------------- CHECK VERIFICATION ----------------
  Future<void> checkVerification({bool auto = false}) async {
    if (!auto) setState(() => loading = true);

    await auth.reloadUser();
    final user = auth.user;

    if (user != null && user.emailVerified) {
      /// ✅ Create Firestore user (only once safe)
      final newUser = UserModel(
        uid: user.uid,
        email: user.email!,
        name: user.displayName ?? '',
        bio: 'Hey 👋 I am using ChatPal',
        profilePicture: '',
        isOnline: true,
      );

      await AppServices.firestore.createOrUpdateUser(newUser);

      _timer?.cancel();

      if (!mounted) return;

      setState(() => loading = false);

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!auto) {
        setState(() => loading = false);
        _show("Still not verified");
      }
    }
  }

  /// ---------------- RESEND EMAIL ----------------
  Future<void> resendEmail() async {
    try {
      await auth.resendVerificationEmail();

      _show("Verification email sent again");
    } catch (e) {
      _show("Failed to resend email");
    }
  }

  /// ---------------- SNACKBAR ----------------
  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mark_email_read, size: 80, color: Colors.blue),

            SizedBox(height: 20),

            Text(
              "Verify your email",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Text(
              "We have sent a verification link to your email.\n"
                  "Please verify to continue.",
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 30),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () => checkVerification(),
              child: Text("I Verified"),
            ),

            SizedBox(height: 10),

            TextButton(
              onPressed: resendEmail,
              child: Text("Resend Email"),
            ),
          ],
        ),
      ),
    );
  }
}