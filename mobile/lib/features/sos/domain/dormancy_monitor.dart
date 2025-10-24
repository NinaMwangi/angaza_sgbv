import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';

class DormancyMonitor {
  final VoidCallback onAutoTrigger;
  DormancyMonitor({required this.onAutoTrigger});

  StreamSubscription? _sub;
  final _win = <double>[];
  DateTime _lastMove = DateTime.now();
  bool _armed = false;

  void start(){
    _armed = true;
    _sub = accelerometerEventStream().listen((e){
      final g = sqrt(e.x*e.x + e.y*e.y + e.z*e.z);
      _win.add(g);
      if (_win.length>40) _win.removeAt(0); // ~1s window at 40Hz typical
      final mean = _win.isEmpty ? 0 : _win.reduce((a,b)=>a+b)/_win.length;
      final varc = _win.fold(0.0, (s,v)=> s + (v-mean)*(v-mean)) / max(1,_win.length);
      if (varc > 0.05) _lastMove = DateTime.now(); // moving
      if (_armed && DateTime.now().difference(_lastMove) > const Duration(minutes: 2)) {
        _armed = false;
        onAutoTrigger(); // caller should show prompt/cancel window
      }
    });
  }
  void stop(){ _sub?.cancel(); _sub=null; _armed=false; _win.clear(); }
}
