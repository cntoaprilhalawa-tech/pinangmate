import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/services/location_service.dart';
import '../core/load_status.dart';

enum HargaFilter { semua, gratis, hemat, sedang, mahal }

extension HargaFilterLabel on HargaFilter {
  String get label {
    switch (this) {
      case HargaFilter.semua:
        return 'Semua harga';
      case HargaFilter.gratis:
        return 'Gratis';
      case HargaFilter.hemat:
        return 'Sampai Rp 50.000';
      case HargaFilter.sedang:
        return 'Rp 50.000 – 200.000';
      case HargaFilter.mahal:
        return 'Di atas Rp 200.000';
    }
  }

  bool cocok(int harga) {
    switch (this) {
      case HargaFilter.semua:
        return true;
      case HargaFilter.gratis:
        return harga <= 0;
      case HargaFilter.hemat:
        return harga > 0 && harga <= 50000;
      case HargaFilter.sedang:
        return harga > 50000 && harga <= 200000;
      case HargaFilter.mahal:
        return harga > 200000;
    }
  }
}

class CategoryListViewModel extends ChangeNotifier {
  CategoryListViewModel(this._repo, this.kategori, this._loc) {
    _listen();
  }

  final ItemRepository _repo;
  final LocationService _loc;
  Timer? _offlineTimer;
  bool _disposed = false;

  bool offline = false;
  bool terdekat = false;
  bool lokasiLoading = false;
  bool lokasiDitolakPermanen = false;
  ({double lat, double lng})? posisi;

  final Kategori kategori;

  StreamSubscription<dynamic>? _sub;

  LoadStatus status = LoadStatus.loading;
  List<Item> all = const [];

  String query = '';
  String? tag; // null = Semua
  HargaFilter harga = HargaFilter.semua;

  bool get filterAktif =>
      query.trim().isNotEmpty || tag != null || harga != HargaFilter.semua;

  /// Semua tag yang ada di data, urut abjad.
  List<String> get tags {
    final set = <String>{};
    for (final i in all) {
      set.addAll(i.tag);
    }
    return set.toList()..sort();
  }

  List<Item> get filtered {
    final q = query.trim().toLowerCase();
    final hasil = all.where((i) {
      if (tag != null && !i.tag.contains(tag)) return false;
      if (!harga.cocok(i.harga)) return false;
      if (q.isEmpty) return true;
      return i.nama.toLowerCase().contains(q) ||
          i.deskripsi.toLowerCase().contains(q) ||
          (i.alamat ?? '').toLowerCase().contains(q);
    }).toList();
    final p = posisi;
    if (terdekat && p != null) {
      hasil.sort((a, b) => LocationService.jarakMeter(p.lat, p.lng, a.lat, a.lng)
          .compareTo(LocationService.jarakMeter(p.lat, p.lng, b.lat, b.lng)));
    }
    return hasil;
  }

  void setQuery(String v) {
    query = v;
    notifyListeners();
  }

  void setTag(String? v) {
    tag = (tag == v) ? null : v; // tekan lagi untuk batal
    notifyListeners();
  }

  void setHarga(HargaFilter v) {
    harga = v;
    notifyListeners();
  }

  void reset() {
    query = '';
    tag = null;
    harga = HargaFilter.semua;
    notifyListeners();
  }

  void _listen() {
    _sub?.cancel();
    status = LoadStatus.loading;
    notifyListeners();
    _sub = _repo.watchByKategoriMeta(kategori).listen(
      (r) {
        all = r.$1;
        status = all.isEmpty ? LoadStatus.empty : LoadStatus.ready;
        _setOffline(r.$2);
        notifyListeners();
      },
      onError: (Object e) {
        status = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  /// Banner baru muncul kalau data dari cache bertahan 2 detik,
  /// supaya tidak berkedip saat pemuatan awal.
  void _setOffline(bool fromCache) {
    _offlineTimer?.cancel();
    if (!fromCache) {
      offline = false;
      return;
    }
    _offlineTimer = Timer(const Duration(seconds: 2), () {
      offline = true;
      if (!_disposed) notifyListeners();
    });
  }

  /// Mengembalikan pesan untuk snackbar, atau null kalau berhasil.
  Future<String?> toggleTerdekat() async {
    if (terdekat) {
      terdekat = false;
      notifyListeners();
      return null;
    }
    lokasiLoading = true;
    notifyListeners();
    final r = await _loc.ambil();
    if (_disposed) return null;
    lokasiLoading = false;
    lokasiDitolakPermanen = r.status == LokasiStatus.ditolakPermanen;
    if (r.status == LokasiStatus.ok) {
      posisi = (lat: r.lat!, lng: r.lng!);
      terdekat = true;
      notifyListeners();
      return null;
    }
    notifyListeners();
    return switch (r.status) {
      LokasiStatus.layananMati => 'Nyalakan GPS di pengaturan HP dulu.',
      LokasiStatus.ditolak =>
        'Izin lokasi ditolak, jadi urutan terdekat tidak bisa dipakai.',
      LokasiStatus.ditolakPermanen =>
        'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.',
      _ => 'Gagal mendapatkan lokasi. Coba lagi di tempat terbuka.',
    };
  }

  Future<void> bukaPengaturan() => _loc.bukaPengaturan();

  String? jarakLabel(Item i) {
    final p = posisi;
    if (!terdekat || p == null) return null;
    final m = LocationService.jarakMeter(p.lat, p.lng, i.lat, i.lng);
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  void retry() => _listen();

  @override
  void dispose() {
    _disposed = true;
    _offlineTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}