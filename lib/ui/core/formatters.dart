const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatRupiah(int value) {
  if (value <= 0) return 'Gratis';
  final s = value
      .toString()
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return 'Rp $s';
}

/// '4,5 (12)' atau 'Belum ada nilai'.
String formatRating(double avg, int count) {
  if (count == 0) return 'Belum ada nilai';
  return '${avg.toStringAsFixed(1).replaceAll('.', ',')} ($count)';
}

String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

DateTime _wib(DateTime d) => d.toUtc().add(const Duration(hours: 7));

/// '13–15 Jun 2026', '30 Jun – 2 Jul 2026', atau satu tanggal bila sehari.
String formatRentang(DateTime mulai, DateTime selesai) {
  final a = _wib(mulai);
  final b = _wib(selesai);
  final sameYear = a.year == b.year;
  final sameMonth = sameYear && a.month == b.month;
  if (sameMonth && a.day == b.day) return formatTanggal(a);
  if (sameMonth) return '${a.day}–${b.day} ${_bulan[a.month - 1]} ${a.year}';
  if (sameYear) {
    return '${a.day} ${_bulan[a.month - 1]} – ${b.day} ${_bulan[b.month - 1]} ${a.year}';
  }
  return '${formatTanggal(a)} – ${formatTanggal(b)}';
}