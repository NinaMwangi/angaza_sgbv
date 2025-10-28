import 'dart:math';

class Triple {
  final double x, y, z;
  Triple(this.x, this.y, this.z);
}

class FeatureExtractor {
  /// Returns features in a fixed order:
  /// For each sensor in [acc, gyro], for each axis [x,y,z]:
  /// [mean, std, min, max, rms, skew, kurt]
  /// Then per-sensor magnitude [mag_mean, mag_std].
  static List<double> extract({
    required List<Triple> acc,
    required List<Triple> gyro,
  }) {
    List<double> feats = [];
    feats.addAll(_axisFeatures(acc.map((e) => e.x).toList()));
    feats.addAll(_axisFeatures(acc.map((e) => e.y).toList()));
    feats.addAll(_axisFeatures(acc.map((e) => e.z).toList()));
    feats.addAll(_axisFeatures(gyro.map((e) => e.x).toList()));
    feats.addAll(_axisFeatures(gyro.map((e) => e.y).toList()));
    feats.addAll(_axisFeatures(gyro.map((e) => e.z).toList()));

    // magnitudes
    final accMag = acc.map((e) => sqrt(e.x*e.x + e.y*e.y + e.z*e.z)).toList();
    final gyrMag = gyro.map((e) => sqrt(e.x*e.x + e.y*e.y + e.z*e.z)).toList();
    feats.addAll(_magFeatures(accMag));
    feats.addAll(_magFeatures(gyrMag));

    return feats;
  }

  static List<double> _axisFeatures(List<double> xs) {
    if (xs.isEmpty) return List.filled(7, 0.0);
    final n = xs.length.toDouble();
    final mean = xs.reduce((a,b)=>a+b) / n;
    double s2 = 0, s3 = 0, s4 = 0;
    double mn = xs.first, mx = xs.first, sq = 0;
    for (final x in xs) {
      final d = x - mean;
      s2 += d*d; s3 += d*d*d; s4 += d*d*d*d;
      if (x < mn) mn = x;
      if (x > mx) mx = x;
      sq += x*x;
    }
    final var_ = s2 / n;
    final std = sqrt(max(0.0, var_));
    final rms = sqrt(sq / n);
    final skew = (std > 1e-12) ? (s3 / n) / pow(std, 3) : 0.0;
    final kurt = (std > 1e-12) ? (s4 / n) / pow(std, 4) : 0.0;
    return [mean, std, mn, mx, rms, skew, kurt];
  }

  static List<double> _magFeatures(List<double> m) {
    if (m.isEmpty) return [0.0, 0.0];
    final n = m.length.toDouble();
    final mean = m.reduce((a,b)=>a+b) / n;
    double s2 = 0;
    for (final v in m) { final d = v - mean; s2 += d*d; }
    final std = sqrt(max(0.0, s2/n));
    return [mean, std];
  }
}
