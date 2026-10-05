import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../core/load_status.dart';

class ItemDetailViewModel extends ChangeNotifier {
  ItemDetailViewModel(this._repo, this.id) {
    load();
  }

  final ItemRepository _repo;
  final String id;
  bool _disposed = false;

  LoadStatus status = LoadStatus.loading;
  Item? item;

  Future<void> load() async {
    status = LoadStatus.loading;
    _notify();
    try {
      item = await _repo.getById(id);
      status = item == null ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      status = LoadStatus.error;
    }
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