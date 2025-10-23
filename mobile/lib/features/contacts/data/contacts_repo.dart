import 'package:hive/hive.dart';

class ContactsRepo {
  static final _box = Hive.box('trusted_contacts');

  static List<String> getAll() {
    final list = _box.get('numbers', defaultValue: <String>[]) as List;
    return List<String>.from(list);
  }

  static Future<void> add(String number) async {
    final all = getAll();
    if (!all.contains(number)) { all.add(number); }
    await _box.put('numbers', all);
  }

  static Future<void> remove(String number) async {
    final all = getAll()..remove(number);
    await _box.put('numbers', all);
  }

  static Future<void> replaceAll(List<String> nums) => _box.put('numbers', nums);
}
