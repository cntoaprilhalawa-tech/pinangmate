/// 'lat, lng' dari Google Maps. Pemisah: koma, spasi, atau titik koma.
({double lat, double lng})? parseKoordinat(String raw) {
  final parts = raw
      .trim()
      .split(RegExp(r'[,\s;]+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0]);
  final lng = double.tryParse(parts[1]);
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat: lat, lng: lng);
}

String formatKoordinat(double lat, double lng) => '$lat, $lng';

/// 'Sejarah, religi, sejarah' -> ['sejarah', 'religi'].
List<String> parseTag(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final t in raw.split(',')) {
    final s = t.trim().toLowerCase();
    if (s.isNotEmpty && seen.add(s)) out.add(s);
  }
  return out;
}