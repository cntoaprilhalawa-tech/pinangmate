import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../data/services/nominatim_service.dart';

class PickedLocation {
  const PickedLocation({required this.lat, required this.lng, this.alamat});

  final double lat;
  final double lng;
  final String? alamat;
}

class LocationPickerViewModel extends ChangeNotifier {
  LocationPickerViewModel(this._geo, {LatLng? initial}) : pin = initial;

  final NominatimService _geo;
  bool _disposed = false;
  int _reverseSeq = 0;

  LatLng? pin;
  String? alamat;
  bool searching = false;
  String? message;
  List<GeoResult> results = const [];

  Future<void> search(String raw) async {
    final q = raw.trim();
    if (q.length < 3) {
      message = 'Tulis minimal 3 huruf.';
      results = const [];
      _notify();
      return;
    }
    searching = true;
    message = null;
    _notify();
    try {
      results = await _geo.search(q);
      message = results.isEmpty
          ? 'Tidak ada hasil. Coba kata lain, atau ketuk peta langsung.'
          : null;
    } catch (_) {
      results = const [];
      message = 'Pencarian gagal. Periksa koneksi, atau ketuk peta langsung.';
    }
    searching = false;
    _notify();
  }

  void pilihHasil(GeoResult r) {
    results = const [];
    message = null;
    setPin(LatLng(r.lat, r.lng), alamatLangsung: r.label);
  }

  void setPin(LatLng p, {String? alamatLangsung}) {
    pin = p;
    alamat = alamatLangsung;
    _notify();
    if (alamatLangsung == null) _reverse(p);
  }

  /// Tunggu sebentar supaya ketukan beruntun tidak membanjiri layanan.
  Future<void> _reverse(LatLng p) async {
    final seq = ++_reverseSeq;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (seq != _reverseSeq || _disposed) return;
    try {
      final a = await _geo.reverse(p.latitude, p.longitude);
      if (seq == _reverseSeq && !_disposed) {
        alamat = a;
        _notify();
      }
    } catch (_) {
      // Alamat tidak wajib. Admin boleh mengetik sendiri.
    }
  }

  PickedLocation? hasil() {
    final p = pin;
    if (p == null) return null;
    return PickedLocation(lat: p.latitude, lng: p.longitude, alamat: alamat);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}