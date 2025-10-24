import 'package:hive/hive.dart';
class ContactsRepo {
  static final _box = Hive.box('trusted_contacts');

  static List<Map<String,String>> getAll() {
    final raw = _box.get('entries', defaultValue: <Map<String,String>>[]) as List;
    return raw.map((e) => Map<String,String>.from(e as Map)).toList();
  }

  static Future<void> add({required String name, required String phone}) async {
    final all = getAll();
    if (!all.any((e) => e['phone']==phone)) all.add({'name': name, 'phone': phone});
    await _box.put('entries', all);
  }

  static Future<void> remove(String phone) async {
    final all = getAll()..removeWhere((e) => e['phone']==phone);
    await _box.put('entries', all);
  }
}
