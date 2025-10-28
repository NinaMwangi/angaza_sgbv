import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'app.dart';
import 'services/platform_channels.dart';
import 'features/sos/domain/outbox_service.dart';
import 'core/env/env.dart';
import 'core/theme_controller.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'core/firebase_initializer.dart';

import 'dart:async' show unawaited;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('trusted_contacts');
  await Hive.openBox('outbox');
  await Hive.openBox('incidents');
  await Hive.openBox('settings');
  OrtEnv.instance.init();

  const channel = MethodChannel('app.angaza.sgbv/channel');
  channel.setMethodCallHandler(PlatformChannels.I.handleNativeCall);

  if (Env.apiBase != null) {
    unawaited(OutboxService.trySyncAll());
  }

  runApp(
    ChangeNotifierProvider(create: (_) => ThemeController(), child: const SafeNotesApp()),
  );
}
