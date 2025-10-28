import 'dart:async';
import '../../../core/ml/activity_model.dart';
import '../../sensors/sensor_collector.dart';

typedef DormancyCallback = void Function();

/// Streams sensor windows -> features -> ONNX -> triggers SOS on dormancy.
class DormancyService {
  DormancyService({required this.onDormant});

  final DormancyCallback onDormant;

  final _collector = SensorCollector();
  final _model = ActivityModel();

  bool _enabled = false;
  DateTime? _firstDorm;

  // Tune as needed
  final double _probThresh = 0.80;  // probability threshold for Dormant
  final int _sustainSecs = 3600;    // 60 minutes continuous dormancy

  /// Call once before start(); assumes OrtEnv.instance.init() was called in main()
  Future<void> init() async {
    await _model.load(); // loads assets/ml/best_classification_model.onnx
  }

  void start() {
    if (_enabled) return;
    _enabled = true;
    _collector.start(_onFeatures); // will call back every 1.5s with a 3s window
  }

  void stop() {
    if (!_enabled) return;
    _enabled = false;
    _collector.stop();
    _firstDorm = null;
  }

  void dispose() {
    stop();
    _model.dispose();
    _collector.dispose();
  }

  /// Async because predictAsync returns a Future.
  void _onFeatures(List<double> features) async {
    if (!_model.isReady) return;

    Map<String, dynamic> out;
    try {
      out = await _model.predictAsync(features);
    } catch (_) {
      // If model not ready or output invalid, skip this window gracefully.
      return;
    }

    final cls = out['class'] as int;
    final probs = (out['probs'] as List).cast<double>();
    // Assuming index 0 corresponds to "Dormant"
    final pDorm = (probs.isNotEmpty) ? probs[0] : 0.0;

    final now = DateTime.now();
    if (cls == 0 && pDorm >= _probThresh) {
      _firstDorm ??= now;
      final sustain = now.difference(_firstDorm!).inSeconds;
      if (sustain >= _sustainSecs) {
        _firstDorm = null; // reset so we don't loop
        onDormant();
      }
    } else {
      _firstDorm = null;
    }
  }
}
