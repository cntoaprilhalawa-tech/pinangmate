import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';

class ItemRepository {
  ItemRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Data aktif satu kategori, urut nama (untuk pengunjung).
  Stream<List<Item>> watchByKategori(Kategori k) {
    return _db
        .collection('items')
        .where('kategori', isEqualTo: k.name)
        .where('aktif', isEqualTo: true)
        .snapshots()
        .map(_toSortedList);
  }

  /// Semua data satu kategori, termasuk yang nonaktif (untuk admin).
  Stream<List<Item>> watchAllByKategori(Kategori k) {
    return _db
        .collection('items')
        .where('kategori', isEqualTo: k.name)
        .snapshots()
        .map(_toSortedList);
  }

  List<Item> _toSortedList(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => Item.fromMap(d.id, d.data())).toList();
    list.sort((a, b) => a.nama.compareTo(b.nama));
    return list;
  }

  Future<Item?> getById(String id) async {
    final doc = await _db.collection('items').doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return Item.fromMap(doc.id, data);
  }

  /// Tambah data baru (ID otomatis), rating dimulai dari nol.
  Future<void> create(Item item) async {
    final data = item.toMap();
    data['ratingSum'] = 0;
    data['ratingCount'] = 0;
    await _db.collection('items').doc().set(data);
  }

  /// Ubah data. Rating tidak disentuh.
  Future<void> update(String id, Item item) {
    final data = item.toMap()
      ..remove('ratingSum')
      ..remove('ratingCount');
    return _db
        .collection('items')
        .doc(id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> delete(String id) => _db.collection('items').doc(id).delete();
}