import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../models/plan.dart';
import '../models/plan_codec.dart';

class PlanRepository {
  PlanRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Semua data aktif dari keempat kategori, bahan algoritma paket liburan.
  Future<List<Item>> ambilSemuaAktif() async {
    final snap =
        await _db.collection('items').where('aktif', isEqualTo: true).get();
    return snap.docs.map((d) => Item.fromMap(d.id, d.data())).toList();
  }

  CollectionReference<Map<String, dynamic>> _koleksi(String uid) =>
      _db.collection('users').doc(uid).collection('plans');

  /// Mengembalikan ID dokumen. Offline, Future ini baru selesai saat online.
  Future<String> simpan(String uid, Plan plan) async {
    final ref = _koleksi(uid).doc();
    await ref.set({
      ...planToMap(plan),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<SavedPlan>> pantau(String uid) {
    return _koleksi(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final list = <SavedPlan>[];
      for (final d in snap.docs) {
        final p = SavedPlan.tryParse(d.id, d.data());
        if (p != null) list.add(p);
      }
      return list;
    });
  }

  Future<SavedPlan?> ambil(String uid, String id) async {
    final doc = await _koleksi(uid).doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return SavedPlan.tryParse(doc.id, data);
  }

  Future<void> hapus(String uid, String id) => _koleksi(uid).doc(id).delete();
}