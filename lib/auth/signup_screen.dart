import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final name = TextEditingController();

  final auth = AuthService();
  bool loading = false;

  void signup() async {
    setState(() => loading = true);

    try {
      final user = await auth.signUp(
        email.text.trim(),
        pass.text.trim(),
      );

      setState(() => loading = false);

      if (user != null) {
        /// optionally store name in Firebase Auth
        await user.updateDisplayName(name.text.trim());

        Navigator.pushReplacementNamed(context, '/verify');
      }
    } catch (e) {
      setState(() => loading = false);

      if (e == 'email-already-in-use') {
        _show("Email already in use");
      } else if (e == 'invalid-email') {
        _show("Invalid email");
      } else if (e == 'weak-password') {
        _show("Weak password");
      } else {
        _show("Signup failed");
      }
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: "Password")),

            SizedBox(height: 20),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: signup,
              child: Text("Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}