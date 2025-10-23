import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter/services.dart';
import 'services/platform_channels.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.angaza.sgbv/channel');
  channel.setMethodCallHandler(PlatformChannels.I.handleNativeCall);
  runApp(const SafeNotesApp());
}
