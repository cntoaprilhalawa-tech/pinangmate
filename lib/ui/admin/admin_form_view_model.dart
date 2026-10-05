import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../core/load_status.dart';

class AdminFormViewModel extends ChangeNotifier {
  AdminFormViewModel(this._repo, {this.id, required this.kategori}) {
    if (id != null) {
      load();
    } else {
      status = LoadStatus.ready;
    }
  }

  final ItemRepository _repo;
  final String? id;
  Kategori kategori;
  bool _disposed = false;

  LoadStatus status = LoadStatus.loading;
  Item? item;
  bool saving = false;
  String? saveError;

  bool get isEdit => id != null;

  Future<void> load() async {
    status = LoadStatus.loading;
    _notify();
    try {
      final result = await _repo.getById(id!);
      if (result == null) {
        status = LoadStatus.empty;
      } else {
        item = result;
        kategori = result.kategori;
        status = LoadStatus.ready;
      }
    } catch (_) {
      status = LoadStatus.error;
    }
    _notify();
  }

  Future<bool> save(Item data) async {
    saving = true;
    saveError = null;
    _notify();
    try {
      if (isEdit) {
        await _repo.update(id!, data);
      } else {
        await _repo.create(data);
      }
      saving = false;
      _notify();
      return true;
    } catch (_) {
      saving = false;
      saveError = 'Gagal menyimpan. Cek koneksi dan izin admin.';
      _notify();
      return false;
    }
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