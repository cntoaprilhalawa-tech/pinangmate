import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/rating_repository.dart';
import '../auth/auth_view_model.dart';

class RatingViewModel extends ChangeNotifier {
  RatingViewModel(this._repo, this._auth, this.itemId) {
    _auth.addListener(_onAuth);
    _onAuth();
  }

  final RatingRepository _repo;
  final AuthViewModel _auth;
  final String itemId;

  String? _uid;
  bool _disposed = false;

  int? nilai; // nilai milik pengguna ini, null = belum menilai
  bool loading = false;
  bool saving = false;
  String? error;

  Future<void> _onAuth() async {
    final uid = _auth.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    nilai = null;
    error = null;
    if (uid == null) {
      loading = false;
      _notify();
      return;
    }
    loading = true;
    _notify();
    try {
      final v = await _repo.getMyRating(uid, itemId);
      if (uid == _uid) nilai = v;
    } catch (_) {
      // Gagal baca: anggap belum menilai.
    }
    if (uid == _uid) loading = false;
    _notify();
  }

  void clearError() {
    error = null;
    _notify();
  }

  /// true kalau berhasil.
  Future<bool> submit(int nilaiBaru) async {
    final uid = _uid;
    if (uid == null) return false;
    saving = true;
    error = null;
    _notify();
    try {
      await _repo
          .setRating(uid: uid, itemId: itemId, nilai: nilaiBaru)
          .timeout(const Duration(seconds: 15));
      nilai = nilaiBaru;
      saving = false;
      _notify();
      return true;
    } on TimeoutException {
      error = 'Koneksi lambat atau terputus. Coba lagi.';
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        error = 'Perlu koneksi internet untuk memberi nilai.';
      } else if (e.code == 'permission-denied') {
        error = 'Tidak diizinkan. Coba keluar lalu masuk lagi.';
      } else {
        error = 'Gagal menyimpan nilai.';
      }
    } catch (_) {
      error = 'Gagal menyimpan nilai.';
    }
    saving = false;
    _notify();
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuth);
    super.dispose();
  }
}