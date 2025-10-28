import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

/// ONNX wrapper for activity classification.
/// Tested with onnxruntime: ^1.4.1
class ActivityModel {
  OrtSession? _session;
  String? _inputName;

  bool get isReady => _session != null;

  /// Call once (e.g., in initState of the service) after OrtEnv.instance.init()
  Future<void> load({String assetPath = 'assets/ml/best_classification_model.onnx'}) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();

    final sessionOptions = OrtSessionOptions();
    try {
      _session = OrtSession.fromBuffer(bytes, sessionOptions);
      _inputName = _session!.inputNames.first;
    } finally {
      // Per onnxruntime package guidance
      sessionOptions.release();
    }
  }

  /// Predict asynchronously.
  /// Returns: {'class': int, 'probs': List<double>}
  Future<Map<String, dynamic>> predictAsync(List<double> features) async {
    final s = _session;
    if (s == null) {
      throw StateError('ActivityModel not loaded (call load() first)');
    }

    // Build input tensor [1, n_feats]
    final input = Float32List.fromList(features.map((e) => e.toDouble()).toList());
    final tensor = OrtValueTensor.createTensorWithDataList(input, [1, features.length]);

    final runOptions = OrtRunOptions();
    List<OrtValue?> outputs = const <OrtValue?>[];
    try {
      final outputsNullable = await s.runAsync(runOptions, {_inputName!: tensor});
      outputs = outputsNullable ?? const <OrtValue?>[];
    } finally {
      // Always release inputs & options
      tensor.release();
      runOptions.release();
    }

    // Parse probability tensor [1, nClasses]
    List<double>? probs;
    for (final ov in outputs) {
      if (ov == null) continue;
      final v = ov.value;
      if (v is List && v.isNotEmpty && v.first is List) {
        final row = v.first as List;
        if (row.isNotEmpty && row.first is num) {
          probs = row.map((e) => (e as num).toDouble()).toList();
          break;
        }
      }
    }

    // Release output OrtValues
    for (final ov in outputs) {
      ov?.release();
    }

    if (probs == null) {
      throw StateError('ONNX probability tensor not found. Re-export with zipmap disabled.');
    }

    // Argmax
    var argmax = 0;
    var best = probs[0];
    for (var i = 1; i < probs.length; i++) {
      if (probs[i] > best) {
        best = probs[i];
        argmax = i;
      }
    }

    return {'class': argmax, 'probs': probs};
  }

  void dispose() {
    _session?.release();
    _session = null;
  }
}
