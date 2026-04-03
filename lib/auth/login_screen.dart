import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();

  final auth = AuthService();
  bool loading = false;

  void login() async {
    setState(() => loading = true);

    try {
      final user = await auth.login(
        email.text.trim(),
        pass.text.trim(),
      );

      if (user != null) {
        if (!user.emailVerified) {
          Navigator.pushReplacementNamed(context, '/verify');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (e == 'user-not-found') {
        _show("User not found");
      } else if (e == 'wrong-password') {
        _show("Wrong password");
      } else if (e == 'invalid-email') {
        _show("Invalid email");
      } else {
        _show("Login failed");
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
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: pass, obscureText: true, decoration: InputDecoration(labelText: "Password")),

            SizedBox(height: 20),

            loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: login,
              child: Text("Login"),
            ),

            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: Text("Create account"),
            )
          ],
        ),
      ),
    );
  }
}