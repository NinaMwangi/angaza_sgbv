import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/platform_channels.dart'; // adjust path if needed

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final StreamSubscription _sub;

  @override
  void initState() {
    super.initState();
    // Listen for Quick Settings tile or widget triggers
    _sub = PlatformChannels.I.onExternalTrigger.listen((_) {
      if (mounted) context.go('/sos');
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: GestureDetector(
        // Hidden gesture: long-press anywhere to open the real Angaza UI
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
