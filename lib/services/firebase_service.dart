import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// All documents in `detections` (no server `orderBy`).
  ///
  /// **Why:** `orderBy('timestamp')` **excludes** documents that have no `timestamp`
  /// field, so hand‑added Firestore entries would never appear on the Field Map or
  /// dashboard. Sort by time in Dart with [sortDetectionsByTimestampDesc] where needed.
  Stream<QuerySnapshot> getDetectionStream() {
    return _db.collection('detections').snapshots();
  }

  /// Newest first; docs without [timestamp] sort to the end.
  static List<QueryDocumentSnapshot> sortDetectionsByTimestampDesc(
    List<QueryDocumentSnapshot> docs,
  ) {
    int millis(QueryDocumentSnapshot d) {
      final raw = d.data();
      final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final t = data['timestamp'];
      if (t is Timestamp) return t.millisecondsSinceEpoch;
      if (t is DateTime) return t.millisecondsSinceEpoch;
      return 0;
    }

    final out = List<QueryDocumentSnapshot>.from(docs);
    out.sort((a, b) => millis(b).compareTo(millis(a)));
    return out;
  }

  /// [gridRow]/[gridCol] are **1-based** (3×20 field grid). Omit for dashboards-only tests.
  Future<void> addTestWeedDetection({
    int gridRow = 2,
    int gridCol = 1,
    bool eliminated = false,
  }) async {
    await _db.collection('detections').add({
      'timestamp': FieldValue.serverTimestamp(),
      'eliminated': eliminated,
      'confidence_level': '94%',
      'type_wp': 'weed',
      'grid_row': gridRow,
      'grid_col': gridCol,
    });
  }

  Future<void> addTestPestDetection({
    int gridRow = 5,
    int gridCol = 3,
    bool eliminated = false,
  }) async {
    await _db.collection('detections').add({
      'timestamp': FieldValue.serverTimestamp(),
      'eliminated': eliminated,
      'confidence_level': '89%',
      'type_wp': 'pest',
      'grid_row': gridRow,
      'grid_col': gridCol,
    });
  }
}