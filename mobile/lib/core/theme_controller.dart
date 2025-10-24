import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeController extends ChangeNotifier {
  static final _box = Hive.box('settings');
  ThemeMode get mode {
    final m = _box.get('theme', defaultValue: 'system');
    return m=='dark' ? ThemeMode.dark : m=='light' ? ThemeMode.light : ThemeMode.system;
  }
  void toggle(){
    final next = mode==ThemeMode.system ? 'dark' : mode==ThemeMode.dark ? 'light' : 'system';
    _box.put('theme', next); notifyListeners();
  }
}
