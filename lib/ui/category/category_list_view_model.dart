import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
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
  CategoryListViewModel(this._repo, this.kategori) {
    _listen();
  }

  final ItemRepository _repo;
  final Kategori kategori;

  StreamSubscription<List<Item>>? _sub;

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
    return all.where((i) {
      if (tag != null && !i.tag.contains(tag)) return false;
      if (!harga.cocok(i.harga)) return false;
      if (q.isEmpty) return true;
      return i.nama.toLowerCase().contains(q) ||
          i.deskripsi.toLowerCase().contains(q) ||
          (i.alamat ?? '').toLowerCase().contains(q);
    }).toList();
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
    _sub = _repo.watchByKategori(kategori).listen(
      (list) {
        all = list;
        status = list.isEmpty ? LoadStatus.empty : LoadStatus.ready;
        notifyListeners();
      },
      onError: (Object e) {
        status = LoadStatus.error;
        notifyListeners();
      },
    );
  }

  void retry() => _listen();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}