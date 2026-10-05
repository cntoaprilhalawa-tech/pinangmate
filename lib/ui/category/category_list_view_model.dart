import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../core/load_status.dart';

class CategoryListViewModel extends ChangeNotifier {
  CategoryListViewModel(this._repo, this.kategori) {
    _listen();
  }

  final ItemRepository _repo;
  final Kategori kategori;
  StreamSubscription<List<Item>>? _sub;

  LoadStatus status = LoadStatus.loading;
  List<Item> items = const [];

  void _listen() {
    _sub?.cancel();
    status = LoadStatus.loading;
    notifyListeners();
    _sub = _repo.watchByKategori(kategori).listen(
      (list) {
        items = list;
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