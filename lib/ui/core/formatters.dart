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

String formatTanggal(DateTime d) {
  const bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${d.day} ${bulan[d.month - 1]} ${d.year}';
}