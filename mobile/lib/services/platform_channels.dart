import 'dart:async';
import 'package:flutter/services.dart';

class PlatformChannels {
  PlatformChannels._();
  static final PlatformChannels I = PlatformChannels._();

  static const _channel = MethodChannel('app.angaza.sgbv/channel');

  final _externalTriggerCtrl = StreamController<void>.broadcast();
  Stream<void> get onExternalTrigger => _externalTriggerCtrl.stream;

  /// Call from native when a QS tile or widget is tapped.
  Future<void> handleNativeCall(MethodCall call) async {
    if (call.method == 'external_sos_trigger') {
      _externalTriggerCtrl.add(null);
    }
  }

  /// Optional: let Dart ask native to collapse panels, etc.
  Future<void> collapsePanels() async {
    try { await _channel.invokeMethod('collapse_panels'); } catch (_) {}
  }
}
