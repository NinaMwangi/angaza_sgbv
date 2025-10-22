import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: GestureDetector(
        // Hidden gesture: long-press header area to open real UI
        onLongPress: () => context.go('/sos'),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            ListTile(title: Text('Grocery list')),
            ListTile(title: Text('Meeting notes')),
            ListTile(title: Text('To-dos')),
          ],
        ),
      ),
    );
  }
}
