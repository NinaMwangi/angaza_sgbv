/// Mobile runtime env 
class Env {
  /// Keep HTTP backend off for now; SMS stays as fallback.
  static const String? apiBase = null;

  /// Use Firebase (Firestore + Storage) for cloud sync.
  static const bool useFirebaseSync = true;

  /// Collection/bucket names used by OutboxService
  static const String incidentsCollection = 'incidents';
  static const String audioFolder = 'audio'; // gs://<bucket>/audio/<id>.m4a

  /// Optional: will later add HTTPS Cloud Functions (callables/REST)
  //static const String functionsRegion = 'us-central1';
}
