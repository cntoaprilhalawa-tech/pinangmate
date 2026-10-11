import 'item.dart';

/// Cocok kalau kata kunci ada di nama, deskripsi, alamat, atau tag.
bool cocokPencarian(Item i, String queryLower) {
  if (queryLower.isEmpty) return false;
  return i.nama.toLowerCase().contains(queryLower) ||
      i.deskripsi.toLowerCase().contains(queryLower) ||
      (i.alamat ?? '').toLowerCase().contains(queryLower) ||
      i.tag.any((t) => t.toLowerCase().contains(queryLower));
}

/// Nama yang cocok didahulukan, lalu urut nama.
List<Item> cariItem(List<Item> semua, String query, {Kategori? kategori}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final hasil = semua
      .where(
        (i) =>
            (kategori == null || i.kategori == kategori) &&
            cocokPencarian(i, q),
      )
      .toList();
  hasil.sort((a, b) {
    final an = a.nama.toLowerCase().contains(q) ? 0 : 1;
    final bn = b.nama.toLowerCase().contains(q) ? 0 : 1;
    if (an != bn) return an.compareTo(bn);
    return a.nama.compareTo(b.nama);
  });
  return hasil;
}