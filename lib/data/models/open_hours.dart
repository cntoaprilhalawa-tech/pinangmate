/// Waktu sekarang di WIB (UTC+7).
DateTime nowWib() => DateTime.now().toUtc().add(const Duration(hours: 7));

int? _menit(String? hhmm) {
  if (hhmm == null) return null;
  final p = hhmm.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// true = buka, false = tutup, null = jam tidak diketahui.
bool? isOpenNow(String? jamBuka, String? jamTutup, {DateTime? now}) {
  final buka = _menit(jamBuka);
  final tutup = _menit(jamTutup);
  if (buka == null || tutup == null) return null;
  final t = now ?? nowWib();
  final sekarang = t.hour * 60 + t.minute;
  if (buka <= tutup) return sekarang >= buka && sekarang < tutup;
  return sekarang >= buka || sekarang < tutup; // lewat tengah malam
}