import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoResult {
  const GeoResult({required this.label, required this.lat, required this.lng});

  final String label;
  final double lat;
  final double lng;
}

/// Klien Nominatim publik. Mengikuti kebijakan penggunaan:
/// User-Agent pengenal aplikasi dan jeda antar permintaan >= 1,1 detik.
class NominatimService {
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent':
        'PinangMate/1.0 (aplikasi tugas kuliah; com.pinangmate.pinangmate)',
  };
  static const _minGap = Duration(milliseconds: 1100);

  Future<void> _tail = Future<void>.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  /// Mengantre permintaan satu per satu dengan jeda minimal.
  Future<T> _throttled<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      final wait = _minGap - DateTime.now().difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _last = DateTime.now();
      }
    });
    return completer.future;
  }

  Future<List<GeoResult>> search(String query) => _throttled(() async {
        final uri = Uri.https(_host, '/search', {
          'q': query,
          'format': 'jsonv2',
          'limit': '5',
          'countrycodes': 'id',
          'accept-language': 'id',
        });
        final res = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          throw Exception('Nominatim ${res.statusCode}');
        }
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) {
          final m = e as Map<String, dynamic>;
          return GeoResult(
            label: (m['display_name'] as String?) ?? '',
            lat: double.parse(m['lat'] as String),
            lng: double.parse(m['lon'] as String),
          );
        }).toList();
      });

  /// Alamat teks dari koordinat, null kalau tidak ketemu.
  Future<String?> reverse(double lat, double lng) => _throttled(() async {
        final uri = Uri.https(_host, '/reverse', {
          'lat': '$lat',
          'lon': '$lng',
          'format': 'jsonv2',
          'zoom': '18',
          'accept-language': 'id',
        });
        final res = await _client
            .get(uri, headers: _headers)
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) return null;
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final name = m['display_name'] as String?;
        return name?.replaceAll(RegExp(r',\s*Indonesia$'), '');
      });
}