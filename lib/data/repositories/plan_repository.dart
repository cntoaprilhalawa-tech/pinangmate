import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

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
}