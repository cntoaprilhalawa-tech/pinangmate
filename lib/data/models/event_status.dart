import 'item.dart';

enum EventStatus { akanDatang, berlangsung, selesai }

EventStatus? eventStatus(DateTime? mulai, DateTime? selesai, {DateTime? now}) {
  if (mulai == null || selesai == null) return null;
  final t = now ?? DateTime.now();
  if (t.isBefore(mulai)) return EventStatus.akanDatang;
  if (t.isAfter(selesai)) return EventStatus.selesai;
  return EventStatus.berlangsung;
}

String eventStatusLabel(EventStatus s) {
  switch (s) {
    case EventStatus.akanDatang:
      return 'Akan datang';
    case EventStatus.berlangsung:
      return 'Berlangsung';
    case EventStatus.selesai:
      return 'Selesai';
  }
}

/// Berlangsung dulu, lalu akan datang (terdekat), lalu selesai (terbaru).
List<Item> sortEvents(List<Item> items, {DateTime? now}) {
  int rank(Item i) {
    switch (eventStatus(i.tanggalMulai, i.tanggalSelesai, now: now)) {
      case EventStatus.berlangsung:
        return 0;
      case EventStatus.akanDatang:
        return 1;
      case EventStatus.selesai:
        return 2;
      case null:
        return 3;
    }
  }

  final list = [...items];
  list.sort((a, b) {
    final ra = rank(a);
    final rb = rank(b);
    if (ra != rb) return ra.compareTo(rb);
    final ma = a.tanggalMulai;
    final mb = b.tanggalMulai;
    if (ma == null || mb == null) return a.nama.compareTo(b.nama);
    return ra == 2 ? mb.compareTo(ma) : ma.compareTo(mb);
  });
  return list;
}