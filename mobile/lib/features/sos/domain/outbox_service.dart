import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:async' show unawaited; 

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/storage_service.dart';
import '../../../core/env/env.dart';

class OutboxService {
  static final _box = Hive.box('outbox');
  static final _uuid = const Uuid();

  /// Enqueue locally; attempt immediate sync.
  static Future<String> enqueue({
    required List<String> recipients,
    required String message,
    double? lat,
    double? lng,
    String? audioPath,
  }) async {
    final id = _uuid.v4();
    final item = {
      'id': id,
      'ts': DateTime.now().toIso8601String(),
      'recipients': recipients,
      'message': message,
      'lat': lat,
      'lng': lng,
      'audioPath': audioPath,
      'status': 'queued',
      'attempts': 0,
      'lastError': null,
    };
    await _box.put(id, jsonEncode(item));

    // Try to push immediately (non-blocking for UI)
    unawaited(_trySyncOne(id));
    return id;
  }

  /// Try syncing everything in the box.
  static Future<void> trySyncAll() async {
    if (!Env.useFirebaseSync) return;  
    for (final key in _box.keys) {
      await _trySyncOne(key as String);
    }
  }

  /// Internal: push one item to Firebase.
  static Future<void> _trySyncOne(String id) async {
    final raw = _box.get(id);
    if (raw == null) return;
    final it = Map<String, dynamic>.from(jsonDecode(raw as String));

    // Already sent?
    if (it['status'] == 'sent') return;

    try {
      // Ensure auth (anonymous is fine)
      final uid = await _ensureUser();

      // 1) Upload audio via StorageService
      String? audioUrl;
      final audioPath = it['audioPath'] as String?;
      if (audioPath != null && audioPath.isNotEmpty && File(audioPath).existsSync()) {
        audioUrl = await StorageService.uploadFile(
          userId: uid,
          incidentId: it['id'],
          localPath: audioPath,
        );
      }


      // 2) Write/merge incident in Firestore
      final doc = FirebaseFirestore.instance
          .collection('incidents')
          .doc(it['id']);

      await doc.set({
        'id': it['id'],
        'userId': uid,
        'timestamp': it['ts'],
        'lat': it['lat'],
        'lng': it['lng'],
        'recipients': List<String>.from(it['recipients'] ?? const []),
        'message': it['message'],
        'audioUrl': audioUrl,
        'status': 'sent',
      }, SetOptions(merge: true));

      // 3) Mark local as sent
      it['status'] = 'sent';
      it['lastError'] = null;
      await _box.put(id, jsonEncode(it));
    } catch (e) {
      // Backoff bookkeeping
      it['status'] = 'queued';
      it['attempts'] = (it['attempts'] as int) + 1;
      it['lastError'] = e.toString();
      await _box.put(id, jsonEncode(it));
      // Leave queued; will retry on next trySyncAll()
    }
  }

  static Future<String> _ensureUser() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user!;
    return user.uid;
  }
}
