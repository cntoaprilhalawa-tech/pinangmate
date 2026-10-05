import 'item.dart';

/// "Populer": nilai rata-rata tertinggi, lalu jumlah penilai terbanyak,
/// lalu nama. Fungsi murni, mudah diuji.
List<Item> popularItems(List<Item> items, {int limit = 6}) {
  final list = [...items];
  list.sort((a, b) {
    final byAvg = b.ratingAvg.compareTo(a.ratingAvg);
    if (byAvg != 0) return byAvg;
    final byCount = b.ratingCount.compareTo(a.ratingCount);
    if (byCount != 0) return byCount;
    return a.nama.compareTo(b.nama);
  });
  return list.take(limit).toList();
}