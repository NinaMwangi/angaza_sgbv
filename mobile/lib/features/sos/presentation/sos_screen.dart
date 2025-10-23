import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/permissions.dart';
import '../../contacts/data/contacts_repo.dart';
import '../domain/outbox_service.dart';
import '../domain/recording_service.dart';
import '../widgets/sos_button.dart';
import 'cancel_sheet.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActive = false;
  Position? _lastPos;
  final _rec = RecordingService();

  List<String> get _trustedNumbers => ContactsRepo.getAll();

  Future<void> _onTrigger() async {
    setState(() => _sosActive = true);

    // Permissions
    final okLoc = await AppPermissions.ensureLocation();
    final okMic = await AppPermissions.ensureMic(); // mic for recording
    if (!okLoc) {
      setState(() => _sosActive = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission is required.')));
      return;
    }

    // Start recording (best effort)
    String? audioPath;
    if (okMic) {
      audioPath = await _rec.start(maxSeconds: 60);
    }

    // Get location fast
    try {
      _lastPos = await Geolocator.getLastKnownPosition();
      _lastPos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {}

    final ts = DateTime.now().toIso8601String();
    final lat = _lastPos?.latitude;
    final lng = _lastPos?.longitude;
    final maps = (lat != null && lng != null) ? 'https://maps.google.com/?q=$lat,$lng' : 'Location unavailable';
    final body = 'ANGAZA SOS: I need help.\nTime: $ts\nLocation: $maps';

    // Queue to outbox (server send when Env.apiBase is set)
    await OutboxService.enqueue(
      recipients: _trustedNumbers,
      message: body,
      lat: lat,
      lng: lng,
      audioPath: audioPath,
    );

    if (!mounted) return;

    // Preview + Send via SMS fallback now
    await showModalBottomSheet(
      context: context,
      builder: (_) => _PreviewSheet(
        contacts: _trustedNumbers,
        message: body,
        onSend: () async {
          for (final number in _trustedNumbers) {
            final uri = Uri.parse('sms:$number?body=${Uri.encodeComponent(body)}');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );

    // Cancel sheet (gives user a way to stop recording + send "I'm safe" later)
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => CancelSheet(onCancel: _onCancel),
    );
  }

  void _onCancel() async {
    await _rec.cancelAndDelete(); // stop & delete audio
    setState(() => _sosActive = false);
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert canceled.")));
  }

  @override
  Widget build(BuildContext context) {
    final lat = _lastPos?.latitude?.toStringAsFixed(5);
    final lng = _lastPos?.longitude?.toStringAsFixed(5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Angaza • Emergency'),
        actions: [
          IconButton(
            tooltip: 'Trusted contacts',
            onPressed: () => context.go('/contacts'),
            icon: const Icon(Icons.group_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('This alert will send:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('• Time: ${DateTime.now()}'),
                  Text('• Location: ${lat != null && lng != null ? '$lat, $lng' : 'unknown'}'),
                  const SizedBox(height: 8),
                  const Text('To contacts:', style: TextStyle(fontWeight: FontWeight.w600)),
                  if (_trustedNumbers.isEmpty)
                    const Text('No contacts added yet (tap the group icon above).')
                  else
                    Wrap(spacing: 8, children: _trustedNumbers.map((n) => Chip(label: Text(n))).toList()),
                ]),
              ),
            ),
            const Spacer(),
            SosButton(label: _sosActive ? 'SENDING…' : 'SOS', onPressed: _sosActive ? null : _onTrigger),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Dormancy auto-SOS')),
                Switch(value: false, onChanged: (_) {/* later */}),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => context.go('/'), child: const Text('Quick escape to Notes')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSheet extends StatelessWidget {
  final List<String> contacts;
  final String message;
  final Future<void> Function() onSend;
  const _PreviewSheet({required this.contacts, required this.message, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Review alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          const Text('Recipients:', style: TextStyle(fontWeight: FontWeight.w600)),
          Wrap(spacing: 8, children: contacts.map((n) => Chip(label: Text(n))).toList()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await onSend();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opened SMS composer')));
                    }
                  },
                  child: const Text('Send via SMS'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        ]),
      ),
    );
  }
}
