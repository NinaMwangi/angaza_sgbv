import 'dart:convert';
import 'package:hive/hive.dart';

class IncidentsRepo {
  static final _box = Hive.box('incidents'); // open it in main.dart

  static Future<void> add({
    required String id,
    required String ts,
    required List<Map<String,String>> contacts, // [{name,phone}]
    double? lat, double? lng,
    String? audioPath,
    String status = 'queued',
  }) async {
    final rec = {'id':id,'ts':ts,'contacts':contacts,'lat':lat,'lng':lng,'audioPath':audioPath,'status':status};
    await _box.put(id, jsonEncode(rec));
  }

  static List<Map<String,dynamic>> all() =>
    _box.values.map((e)=> Map<String,dynamic>.from(jsonDecode(e as String))).toList();
}
