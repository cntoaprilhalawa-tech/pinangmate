import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/item.dart';

Future<void> _open(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Tidak bisa membuka aplikasi tujuan.')),
    );
  }
}

/// 0852... -> +62852..., 62852... -> +62852..., +62... tetap.
String normalisasiNomor(String raw) {
  final s = raw.replaceAll(RegExp(r'[^0-9+]'), '');
  if (s.startsWith('+')) return s;
  if (s.startsWith('62')) return '+$s';
  if (s.startsWith('0')) return '+62${s.substring(1)}';
  return '+62$s';
}

Future<void> bukaGoogleMaps(BuildContext context, Item item) {
  // Event memakai koordinat, lainnya memakai nama agar kartu tempat
  // dan ulasan Google ikut terbuka.
  final query = item.kategori == Kategori.event
      ? '${item.lat},${item.lng}'
      : '${item.nama} Tanjungpinang';
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
  return _open(context, uri);
}

Future<void> teleponPenyedia(BuildContext context, String kontak) =>
    _open(context, Uri(scheme: 'tel', path: normalisasiNomor(kontak)));

Future<void> whatsappPenyedia(BuildContext context, String kontak) {
  final nomor = normalisasiNomor(kontak).replaceFirst('+', '');
  return _open(context, Uri.https('wa.me', '/$nomor'));
}