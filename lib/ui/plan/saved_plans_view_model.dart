import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/plan_codec.dart';
import '../../data/repositories/plan_repository.dart';
import '../core/load_status.dart';

class SavedPlansViewModel extends ChangeNotifier {
  SavedPlansViewModel(this._repo, this.uid) {
    _listen();
  }

  final PlanRepository _repo;
  final String uid;
  StreamSubscription<List<SavedPlan>>? _sub;

  LoadStatus status = LoadStatus.loading;
  List<SavedPlan> items = const [];

  void _listen() {
    _sub?.cancel();
    status = LoadStatus.loading;
    notifyListeners();
    _sub = _repo.pantau(uid).listen(
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

  /// true kalau berhasil (offline: tulisan diantre dan terkirim saat online).
  Future<bool> hapus(String id) async {
    try {
      await _repo.hapus(uid, id).timeout(const Duration(seconds: 8));
      return true;
    } on TimeoutException {
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}