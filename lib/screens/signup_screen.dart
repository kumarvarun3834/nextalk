import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart' hide FirestoreService;
import 'profile_module.dart';

class ProfileCreationScreen extends StatefulWidget {
  @override
  _ProfileCreationScreenState createState() =>
      _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isLoading = false;

  /// 🚀 Create account
  Future<void> createProfile() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack("Email & password required");
      return;
    }

    if (password != confirm) {
      _showSnack("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      /// 1️⃣ Create Firebase user
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User user = cred.user!;

      /// 2️⃣ Send verification email
      await user.sendEmailVerification();

      setState(() => _isLoading = false);

      /// 3️⃣ Show verification dialog
      _showVerificationDialog(user, email);

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.message ?? "Signup failed");
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Error: $e");
    }
  }

  /// 📩 Verification dialog
  void _showVerificationDialog(User user, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Verify Email"),
        content: Text(
          "Verification link sent to:\n$email\n\nPlease verify before continuing.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await user.reload();
              final refreshed = _auth.currentUser;

              if (refreshed != null && refreshed.emailVerified) {
                Navigator.pop(context);

                /// ✅ Create user in Firestore (NEW MODEL)
                final newUser = UserModel(
                  uid: refreshed.uid,
                  email: email,
                  name: email.split('@')[0], // default name
                  bio: 'Hey 👋 I am using ChatPal',
                  profilePicture: '',
                  isOnline: true,
                  fcmToken: null, // set later
                );

                await _firestoreService.createOrUpdateUser(newUser);

                /// 🚀 Go to profile setup
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSetupScreen(email: email),
                  ),
                );
              } else {
                _showSnack("Email not verified yet");
              }
            },
            child: const Text("I Verified"),
          ),
          TextButton(
            onPressed: () async {
              await user.sendEmailVerification();
              _showSnack("Verification email resent");
            },
            child: const Text("Resend"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),

            const SizedBox(height: 10),

            /// Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),

            const SizedBox(height: 10),

            /// Confirm Password
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration:
              const InputDecoration(labelText: 'Confirm Password'),
            ),

            const SizedBox(height: 20),

            /// Button
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: createProfile,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}