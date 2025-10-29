import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final Widget child; final bool requireEmail; // false = allow anon
  const AuthGate({super.key, required this.child, this.requireEmail=false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        final u = snap.data;
        if (u==null) return const LoginScreen();                  // no user at all
        if (requireEmail && u.isAnonymous) return const LoginScreen();
        return child;
      });
  }
}
