import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart' as login;


/// Wrap your MapPage with this to require an admin claim.
class AdminGate extends StatelessWidget {
  final Widget child; // e.g., MapPage()
  const AdminGate({super.key, required this.child});

  Future<bool> _isAdmin(User user) async {
    final token = await user.getIdTokenResult(true);
    return (token.claims?['admin'] == true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (ctx, snap) {
        // Not signed in → show login
        if (snap.connectionState == ConnectionState.active && snap.data == null) {
          // Defer import to avoid circular dep
          return _LoginLazy();
        }
        if (snap.data == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Check admin claim
        return FutureBuilder<bool>(
          future: _isAdmin(snap.data!),
          builder: (ctx, fs) {
            if (!fs.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (fs.data != true) {
              return Scaffold(
                appBar: AppBar(title: const Text('Angaza Dashboard')),
                body: const Center(child: Text('No access. Ask an admin to grant privileges.')),
              );
            }
            // Admin OK → show child
            return Scaffold(
              appBar: AppBar(
                title: const Text('Angaza Dashboard'),
                actions: [
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              body: child,
            );
          },
        );
      },
    );
  }
}

/// Lazy loader to avoid a direct import loop.
class _LoginLazy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Import here to keep top-level dependencies clean
    // ignore: avoid_types_as_parameter_names
    return const _LoginScreenProxy();
  }
}

class _LoginScreenProxy extends StatelessWidget {
  const _LoginScreenProxy({super.key});
  @override
  Widget build(BuildContext context) {
    // Defers the import to runtime
    return const _LoginScreenEmbed();
  }
}

class _LoginScreenEmbed extends StatelessWidget {
  const _LoginScreenEmbed({super.key});
  @override
  Widget build(BuildContext context) => const login.LoginScreen();
}
