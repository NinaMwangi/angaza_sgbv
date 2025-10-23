import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../../core/env/env.dart';

class OutboxService {
  static final _box = Hive.box('outbox');
  static final _uuid = const Uuid();
  static final _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));

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
    };
    await _box.put(id, jsonEncode(item));
    return id;
  }

  static List<Map<String, dynamic>> _all() {
    return _box.values.map((e) => Map<String, dynamic>.from(jsonDecode(e as String))).toList();
  }

  static Future<void> retryAll() async {
    if (Env.apiBase == null) return; // no backend configured
    final items = _all().where((i) => i['status'] != 'sent').toList();
    for (final it in items) {
      try {
        it['attempts'] = (it['attempts'] as int) + 1;
        await _postToServer(it);
        it['status'] = 'sent';
      } catch (_) {
        it['status'] = 'queued';
      } finally {
        await _box.put(it['id'], jsonEncode(it));
      }
    }
  }

  static Future<void> _postToServer(Map<String, dynamic> it) async {
    final url = '${Env.apiBase}/sos';
    await _dio.post(url, data: {
      'id': it['id'],
      'ts': it['ts'],
      'recipients': it['recipients'],
      'message': it['message'],
      'lat': it['lat'],
      'lng': it['lng'],
      // You can upload audio later to storage; for now we just send path/meta
      'audioPath': it['audioPath'],
    });
  }
}
