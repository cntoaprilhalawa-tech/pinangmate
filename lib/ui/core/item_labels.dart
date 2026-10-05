import '../../data/models/item.dart';
import 'formatters.dart';

/// Teks harga sesuai kategori. null = jangan tampilkan.
String? hargaLabel(Item item) {
  switch (item.kategori) {
    case Kategori.wisata:
      return formatRupiah(item.harga); // 'Gratis' kalau 0
    case Kategori.penginapan:
      return item.harga > 0
          ? 'Mulai ${formatRupiah(item.harga)} / malam'
          : null;
    case Kategori.kuliner:
      return item.harga > 0
          ? 'Mulai ${formatRupiah(item.harga)} / porsi'
          : null;
    case Kategori.event:
      return item.harga > 0 ? formatRupiah(item.harga) : null;
  }
}

/// Rentang tanggal event, null kalau bukan event.
String? tanggalLabel(Item item) {
  final a = item.tanggalMulai;
  final b = item.tanggalSelesai;
  if (a == null || b == null) return null;
  return formatRentang(a, b);
}