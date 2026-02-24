import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of detections ordered by time
  Stream<QuerySnapshot> getDetectionStream() {
    return _db.collection('detections')
              .orderBy('timestamp', descending: true)
              .snapshots();
  }
}

