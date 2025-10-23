import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  final _rec = AudioRecorder();
  String? _path;

  Future<bool> hasPermission() => _rec.hasPermission();

  Future<String?> start({int maxSeconds = 60}) async {
    if (!await _rec.hasPermission()) return null;
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    _path = '${dir.path}/angaza_$ts.m4a';
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 16000),
      path: _path!,
    );
    // Auto-stop after maxSeconds
    Future.delayed(Duration(seconds: maxSeconds), () async {
      if (await _rec.isRecording()) { await stop(); }
    });
    return _path;
  }

  Future<String?> stop() async {
    if (!await _rec.isRecording()) return _path;
    await _rec.stop();
    return _path;
  }

  Future<void> cancelAndDelete() async {
    if (await _rec.isRecording()) { await _rec.stop(); }
    if (_path != null && await File(_path!).exists()) { await File(_path!).delete(); }
    _path = null;
  }
}
