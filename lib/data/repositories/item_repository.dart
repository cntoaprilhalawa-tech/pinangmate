import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

class ItemRepository {
  ItemRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Data aktif satu kategori, urut nama.
  Stream<List<Item>> watchByKategori(Kategori k) {
    return _db
        .collection('items')
        .where('kategori', isEqualTo: k.name)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Item.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => a.nama.compareTo(b.nama));
      return list;
    });
  }

  Future<Item?> getById(String id) async {
    final doc = await _db.collection('items').doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return Item.fromMap(doc.id, data);
  }
}