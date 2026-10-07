import 'package:cloud_firestore/cloud_firestore.dart';

class RatingRepository {
  RatingRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid, String itemId) =>
      _db.collection('ratings').doc('${uid}_$itemId');

  /// Nilai milik pengguna untuk satu tempat, null kalau belum menilai.
  Future<int?> getMyRating(String uid, String itemId) async {
    final doc = await _ref(uid, itemId).get();
    return (doc.data()?['nilai'] as num?)?.toInt();
  }

  /// Simpan atau ubah nilai, sekaligus menggeser ratingSum dan ratingCount
  /// pada dokumen tempat secara atomik. Butuh koneksi internet.
  Future<void> setRating({
    required String uid,
    required String itemId,
    required int nilai,
  }) {
    final ratingRef = _ref(uid, itemId);
    final itemRef = _db.collection('items').doc(itemId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ratingRef);
      final lama = (snap.data()?['nilai'] as num?)?.toInt();
      tx.set(ratingRef, {
        'uid': uid,
        'itemId': itemId,
        'nilai': nilai,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(itemRef, {
        'ratingSum': FieldValue.increment(nilai - (lama ?? 0)),
        'ratingCount': FieldValue.increment(lama == null ? 1 : 0),
      });
    });
  }
}