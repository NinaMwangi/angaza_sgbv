import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter/services.dart';
import 'services/platform_channels.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/sos/domain/outbox_service.dart';
import 'core/env/env.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('trusted_contacts');
  await Hive.openBox('outbox');

  // MethodChannel handler (QS tile / widget triggers)
  const channel = MethodChannel('app.angaza.sgbv/channel');
  channel.setMethodCallHandler(PlatformChannels.I.handleNativeCall);

  if (Env.apiBase != null) {
    unawaited(OutboxService.retryAll());
  }

  runApp(const SafeNotesApp());
}

