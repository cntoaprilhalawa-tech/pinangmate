import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistRepository {
  WishlistRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('wishlist');

  Stream<Set<String>> watchIds(String uid) =>
      _col(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());

  Future<void> add(String uid, String itemId) =>
      _col(uid).doc(itemId).set({'addedAt': FieldValue.serverTimestamp()});

  Future<void> remove(String uid, String itemId) =>
      _col(uid).doc(itemId).delete();
}