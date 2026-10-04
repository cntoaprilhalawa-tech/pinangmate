import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _sub = _repo.authChanges.listen(_onAuthChanged);
  }

  final AuthRepository _repo;
  StreamSubscription<User?>? _sub;

  User? user;
  bool isAdmin = false;
  bool ready = false; // true setelah status login pertama diketahui
  AuthStatus status = AuthStatus.idle;
  String? error;

  bool get loggedIn => user != null;
  bool get loading => status == AuthStatus.loading;

  Future<void> _onAuthChanged(User? u) async {
    user = u;
    isAdmin = false;
    if (u != null) {
      try {
        isAdmin = await _repo.isAdmin(u.uid);
      } catch (_) {
        isAdmin = false;
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repo.login(email: email, password: password));

  Future<bool> register(String nama, String email, String password) => _run(
        () => _repo.register(nama: nama, email: email, password: password),
      );

  Future<bool> resetPassword(String email) =>
      _run(() => _repo.resetPassword(email));

  Future<void> logout() => _repo.logout();

  void clearError() {
    error = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    status = AuthStatus.loading;
    error = null;
    notifyListeners();
    try {
      await action();
      status = AuthStatus.idle;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      error = _pesan(e.code);
    } catch (_) {
      error = 'Terjadi kesalahan, coba lagi.';
    }
    status = AuthStatus.error;
    notifyListeners();
    return false;
  }

  String _pesan(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau kata sandi salah.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar.';
      case 'weak-password':
        return 'Kata sandi terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan, coba lagi nanti.';
      default:
        return 'Terjadi kesalahan, coba lagi.';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}