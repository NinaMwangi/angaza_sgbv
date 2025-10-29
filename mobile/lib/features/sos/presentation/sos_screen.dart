// lib/features/sos/presentation/sos_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:provider/provider.dart';


import '../../../core/permissions.dart';
import '../../../services/platform_channels.dart';
import '../../../core/theme_controller.dart';
import 'cancel_sheet.dart';
import '../widgets/sos_button.dart';

import '../../contacts/data/contacts_repo.dart';
import '../domain/outbox_service.dart';
import '../domain/recording_service.dart';
import '../../incidents/data/incidents_repo.dart';
import '../../sos/domain/dormancy_service.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _sosActive = false;
  bool _dormancyOn = false;

  Position? _lastPos;
  final _rec = RecordingService();

  // Subscriptions
  late final StreamSubscription _externalSub;
  bool _listeningKeys = false;
  int _volCount = 0;
  DateTime _lastVol = DateTime.fromMillisecondsSinceEpoch(0);

  _DormancyMonitor? _dm;

  late DormancyService _dorm;


  @override
  void initState() {
    super.initState();
    _dorm = DormancyService(onDormant: () => _onTrigger());
    _dorm.init().then((_) {
      if (mounted) _dorm.start();
    });
    // Listen for external triggers (QS Tile / Widget / Deep link)
    _externalSub = PlatformChannels.I.onExternalTrigger.listen((_) {
      if (!_sosActive) _onTrigger();
    });

    // Foreground only: volume-up triple-press (best-effort)
    RawKeyboard.instance.addListener(_onRawKey);
    _listeningKeys = true;

    _dorm = DormancyService(onDormant: () => _onTrigger());
    _dorm.init().then((_) {
      if (mounted) _dorm.start();
    });

  }

  @override
  void dispose() {
    _externalSub.cancel();
    if (_listeningKeys) RawKeyboard.instance.removeListener(_onRawKey);
    _dm?.stop();
    _dorm.dispose();
    super.dispose();
  }

  void _onRawKey(RawKeyEvent e) {
    // Many Android devices don’t deliver volume keys to Flutter;
    // this is best-effort when app has focus.
    if (e is RawKeyDownEvent) {
      final name = e.logicalKey.keyLabel.toLowerCase();
      final dbg = e.logicalKey.debugName?.toLowerCase() ?? '';
      if (name.contains('volume') || dbg.contains('volumeup')) {
        final now = DateTime.now();
        _volCount = (now.difference(_lastVol) < const Duration(seconds: 2)) ? _volCount + 1 : 1;
        _lastVol = now;
        if (_volCount >= 3 && !_sosActive) {
          _volCount = 0;
          _onTrigger();
        }
      }
    }
  }

  Future<void> _onTrigger() async {
    setState(() => _sosActive = true);

    // Permissions
    final okLoc = await AppPermissions.ensureLocation();
    final okMic = await AppPermissions.ensureMic();
    if (!okLoc) {
      setState(() => _sosActive = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required for SOS.')),
      );
      return;
    }

    // Start recording (best-effort)
    String? audioPath;
    if (okMic) {
      audioPath = await _rec.start(maxSeconds: 60);
    }

    // Fast location
    try {
      _lastPos = await Geolocator.getLastKnownPosition();
      _lastPos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (_) {}

    // Build recipients (names + numbers)
    final contacts = ContactsRepo.getAll(); // [{name, phone}, ...]
    final numbers  = contacts.map((e) => e['phone']!).toList();
    final names    = contacts.map((e) => e['name'] ?? e['phone']!).toList();

    final ts  = DateTime.now().toIso8601String();
    final lat = _lastPos?.latitude;
    final lng = _lastPos?.longitude;
    final maps = (lat != null && lng != null) ? 'https://maps.google.com/?q=$lat,$lng' : 'Location unavailable';
    final body = 'ANGAZA SOS: I need help.\nTime: $ts\nLocation: $maps';

    // Queue to outbox and write incident (offline log)
    final id = await OutboxService.enqueue(
      recipients: numbers, message: body, lat: lat, lng: lng, audioPath: audioPath,
    );
    await IncidentsRepo.add(
      id: id, ts: ts, contacts: contacts, lat: lat, lng: lng, audioPath: audioPath,
    );

    if (!mounted) return;

    // Preview: show names & message; SMS composer as fallback send
    await showModalBottomSheet(
      context: context,
      builder: (_) => _PreviewSheet(
        names: names,
        message: body,
        onSend: () async {
          for (final c in contacts) {
            final uri = Uri.parse('sms:${c['phone']}?body=${Uri.encodeComponent(body)}');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );

    if (!mounted) return;

    // Cancel window
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => CancelSheet(onCancel: _onCancel),
    );
  }

  void _onCancel() async {
    await _rec.cancelAndDelete();
    setState(() => _sosActive = false);
    if (mounted) {
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alert canceled.')));
    }
  }

  void _toggleDormancy(bool v) {
    setState(() => _dormancyOn = v);
    _dm?.stop();
    if (v) {
      _dm = _DormancyMonitor(onPossibleDormancy: _showDormancyPrompt)..start();
    }
  }

  void _showDormancyPrompt() {
    if (!mounted) return;
    bool canceled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Are you OK?'),
        content: const Text('No movement detected. Sending SOS in 15 seconds…'),
        actions: [
          TextButton(
            onPressed: () { canceled = true; Navigator.pop(context); },
            child: const Text('Cancel'),
          ),
        ],
      ),
    ).then((_) {
      // If user didn’t cancel in time, fire SOS
      if (!canceled && mounted && !_sosActive) _onTrigger();
    });

    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lat = _lastPos?.latitude?.toStringAsFixed(5);
    final lng = _lastPos?.longitude?.toStringAsFixed(5);

    final User? user = FirebaseAuth.instance.currentUser;
    final String label;

    if (user == null) {
      label = 'Signed out';
    } else if (user.isAnonymous) {
      // Here, 'user' is safely known to be non-null
      label = 'Anonymous user';
    } else {
      // 'user' is also non-null here
      label = user.email ?? 'Account';
    }

    return Scaffold(
      appBar: AppBar(
        // Tap title → decoy Notes (home)
        title: GestureDetector(
          onTap: () => context.go('/'),
          child: const Text('Angaza • Emergency'),
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Trusted contacts',
            onPressed: () => context.push('/contacts'),
            icon: const Icon(Icons.group_outlined),
          ),
          IconButton(
            tooltip: 'Theme',
            onPressed: () => context.read<ThemeController>().toggle(),
            icon: const Icon(Icons.brightness_6),
          ),
          IconButton(
            tooltip: 'Account',
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.person_outline),
          ),
        ],

      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Info card: what will be sent & to whom
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
                  _RecipientsChips(),
                ]),
              ),
            ),
            const Spacer(),
            SosButton(
              label: _sosActive ? 'SENDING…' : 'SOS',
              onPressed: _sosActive ? null : _onTrigger,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Dormancy auto-SOS')),
                Switch(value: _dormancyOn, onChanged: _toggleDormancy),
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

// Preview bottom sheet (names + message)
class _PreviewSheet extends StatelessWidget {
  final List<String> names;
  final String message;
  final Future<void> Function() onSend;
  const _PreviewSheet({required this.names, required this.message, required this.onSend});

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
          Wrap(spacing: 8, children: names.map((n) => Chip(label: Text(n))).toList()),
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

// Chips widget (reads contacts repo each build so it stays fresh)
class _RecipientsChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final contacts = ContactsRepo.getAll();
    if (contacts.isEmpty) return const Text('No contacts added yet (tap the group icon above).');
    final names = contacts.map((e) => e['name'] ?? e['phone']!).toList();
    return Wrap(spacing: 8, children: names.map((n) => Chip(label: Text(n))).toList());
  }
}

/// Simple on-device dormancy gate: monitors accelerometer variance; if very low for ~2 minutes,
/// calls back to show a confirmation dialog. If user doesn’t cancel, SOS triggers.
class _DormancyMonitor {
  final VoidCallback onPossibleDormancy;
  _DormancyMonitor({required this.onPossibleDormancy});

  StreamSubscription? _sub;
  final _win = <double>[];
  DateTime _lastMove = DateTime.now();
  bool _armed = false;

  void start() {
    _armed = true;
    _sub = accelerometerEvents.listen((e) {
      final g = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      _win.add(g);
      if (_win.length > 40) _win.removeAt(0); // ~1s window @ ~40Hz
      final mean = _win.isEmpty ? 0 : _win.reduce((a, b) => a + b) / _win.length;
      final varc = _win.fold(0.0, (s, v) => s + (v - mean) * (v - mean)) / max(1, _win.length);
      if (varc > 0.05) _lastMove = DateTime.now(); // movement detected
      if (_armed && DateTime.now().difference(_lastMove) > const Duration(minutes: 2)) {
        _armed = false;
        onPossibleDormancy();
        // re-arm after prompt fires
        _lastMove = DateTime.now();
        _armed = true;
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _armed = false;
    _win.clear();
  }
}