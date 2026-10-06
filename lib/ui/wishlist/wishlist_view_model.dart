import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../auth/auth_view_model.dart';
import '../core/load_status.dart';

class WishlistViewModel extends ChangeNotifier {
  WishlistViewModel(this._wish, this._items, this._auth) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final WishlistRepository _wish;
  final ItemRepository _items;
  final AuthViewModel _auth;

  StreamSubscription<Set<String>>? _sub;
  String? _uid;
  int _seq = 0;
  bool _disposed = false;

  Set<String> ids = {};
  List<Item> items = const [];
  LoadStatus status = LoadStatus.empty;

  bool isFav(String id) => ids.contains(id);

  void _onAuth() {
    final uid = _auth.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    _sub?.cancel();
    ids = {};
    items = const [];
    if (uid == null) {
      status = LoadStatus.empty;
      _notify();
      return;
    }
    status = LoadStatus.loading;
    _notify();
    _sub = _wish.watchIds(uid).listen(_onIds, onError: (Object e) {
      status = LoadStatus.error;
      _notify();
    });
  }

  Future<void> _onIds(Set<String> next) async {
    final seq = ++_seq;
    ids = next; // hati di kartu langsung berubah
    _notify();
    try {
      final res = await Future.wait(next.map(_items.getById));
      if (seq != _seq) return;
      items = res.whereType<Item>().where((i) => i.aktif).toList()
        ..sort((a, b) => a.nama.compareTo(b.nama));
      status = items.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      if (seq != _seq) return;
      status = LoadStatus.error;
    }
    _notify();
  }

  void retry() {
    _uid = null;
    _onAuth();
  }

  /// true kalau berhasil.
  Future<bool> toggle(String itemId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      if (isFav(itemId)) {
        await _wish.remove(uid, itemId);
      } else {
        await _wish.add(uid, itemId);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuth);
    _sub?.cancel();
    super.dispose();
  }
}