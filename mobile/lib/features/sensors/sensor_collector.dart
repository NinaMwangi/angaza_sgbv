import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../core/ml/feature_extractor.dart';

typedef FeaturesReady = void Function(List<double> features);

class SensorCollector {
  final Duration window = const Duration(seconds: 3);
  final Duration hop = const Duration(milliseconds: 1500);

  final _acc = <({DateTime t, double x, double y, double z})>[];
  final _gyr = <({DateTime t, double x, double y, double z})>[];

  StreamSubscription? _accSub;
  StreamSubscription? _gyrSub;
  Timer? _timer;

  void start(FeaturesReady onWindow) {
    stop();

    _accSub = accelerometerEventStream().listen((e) {
      _acc.add((t: DateTime.now(), x: e.x.toDouble(), y: e.y.toDouble(), z: e.z.toDouble()));
      _trim(_acc);
    });
    _gyrSub = gyroscopeEventStream().listen((e) {
      _gyr.add((t: DateTime.now(), x: e.x.toDouble(), y: e.y.toDouble(), z: e.z.toDouble()));
      _trim(_gyr);
    });

    _timer = Timer.periodic(hop, (_) {
      final now = DateTime.now();
      final accWin = _slice(_acc, now.subtract(window));
      final gyrWin = _slice(_gyr, now.subtract(window));
      if (accWin.isEmpty || gyrWin.isEmpty) return;

      final accTriples = accWin.map((e) => Triple(e.x, e.y, e.z)).toList();
      final gyrTriples = gyrWin.map((e) => Triple(e.x, e.y, e.z)).toList();
      final features = FeatureExtractor.extract(acc: accTriples, gyro: gyrTriples);
      onWindow(features);
    });
  }

  void stop() {
    _timer?.cancel(); _timer = null;
    _accSub?.cancel(); _accSub = null;
    _gyrSub?.cancel(); _gyrSub = null;
    _acc.clear(); _gyr.clear();
  }

  void dispose() => stop();

  void _trim(List list) {
    final cutoff = DateTime.now().subtract(window * 2); // keep 2x window
    while (list.isNotEmpty && (list.first as dynamic).t.isBefore(cutoff)) {
      list.removeAt(0);
    }
  }

  List<T> _slice<T>(List<T> data, DateTime since) {
    return data.where((e) => (e as dynamic).t.isAfter(since)).toList().cast<T>();
  }
}
