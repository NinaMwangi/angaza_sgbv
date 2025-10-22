import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/sos_button.dart';
import 'cancel_sheet.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActive = false;

  void _onTrigger() async {
    setState(() => _sosActive = true);
    // TODO: start background service: record, get location, enqueue outbox, send SMS if allowed
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => CancelSheet(onCancel: _onCancel),
      );
    }
  }

  void _onCancel() {
    // TODO: stop recording, send "I'm safe" if configured
    setState(() => _sosActive = false);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: SosButton(
                  label: _sosActive ? 'SENDING…' : 'SOS',
                  onPressed: _sosActive ? null : _onTrigger,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(child: Text('Dormancy auto-SOS')),
                Switch(value: false, onChanged: (_) {/* TODO */}),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Quick escape to Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
