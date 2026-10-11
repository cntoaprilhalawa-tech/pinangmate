import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/models/item_search.dart';
import '../../data/repositories/plan_repository.dart';
import '../core/load_status.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._repo) {
    muat();
  }

  final PlanRepository _repo;
  bool _disposed = false;

  LoadStatus status = LoadStatus.loading;
  List<Item> all = const [];
  String query = '';
  Kategori? kategori; // null = semua

  bool get adaQuery => query.trim().isNotEmpty;

  List<Item> get hasil => cariItem(all, query, kategori: kategori);

  Future<void> muat() async {
    status = LoadStatus.loading;
    _notify();
    try {
      all = await _repo.ambilSemuaAktif();
      status = all.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      status = LoadStatus.error;
    }
    _notify();
  }

  void setQuery(String v) {
    query = v;
    _notify();
  }

  void setKategori(Kategori? k) {
    kategori = (kategori == k) ? null : k; // tekan lagi untuk batal
    _notify();
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