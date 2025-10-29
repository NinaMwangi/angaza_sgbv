import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _busy = false; String? _err;

  Future<void> _signIn() async {
    setState(()=>_busy=true); _err=null;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(), password: _pass.text);
      if (mounted) Navigator.pop(context); // go back to SOS/home
    } on FirebaseAuthException catch (e) {
      setState(()=>_err=e.message??'Login failed');
    } finally { if (mounted) setState(()=>_busy=false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign in')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller:_email, decoration: const InputDecoration(labelText:'Email')),
        const SizedBox(height:8),
        TextField(controller:_pass, decoration: const InputDecoration(labelText:'Password'), obscureText:true),
        if (_err!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text(_err!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height:12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: _busy?null:_signIn, child: _busy?const CircularProgressIndicator():const Text('Sign in')))
      ]),
    ),
  );
}
