import 'package:cloud_firestore/cloud_firestore.dart';

class Incident {
  final String id;
  final double? lat, lng;
  final DateTime ts;
  final String? transcript;
  final String? message;

  Incident({
    required this.id,
    this.lat,
    this.lng,
    required this.ts,
    this.transcript,
    this.message,
  });

  static Incident fromDoc(DocumentSnapshot d) {
    final m = d.data() as Map<String, dynamic>? ?? {};
    return Incident(
      id: d.id,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      ts: DateTime.tryParse(m['timestamp'] ?? '') ?? DateTime.now(),
      transcript: m['transcript'] as String?,
      message: m['message'] as String?,
    );
  }
}

class IncidentsService {
  static Stream<List<Incident>> streamIncidents() {
    return FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Incident.fromDoc).toList());
  }
}
