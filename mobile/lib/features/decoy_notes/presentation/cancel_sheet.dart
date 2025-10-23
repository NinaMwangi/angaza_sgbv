import 'dart:async';
import 'package:flutter/material.dart';

class CancelSheet extends StatefulWidget {
  final VoidCallback onCancel;
  const CancelSheet({super.key, required this.onCancel});
  @override
  State<CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<CancelSheet> {
  int _seconds = 10;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
        // Auto-confirm SOS: keep running background job
        if (mounted) Navigator.of(context).maybePop();
      } else {
        setState(() => _seconds--);
      }
    });
  }
  @override
  void dispose() { _t?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Sending alert in $_seconds s'),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: widget.onCancel,
            child: const Text("I'm safe, cancel"),
          ),
        ]),
      ),
    );
  }
}
