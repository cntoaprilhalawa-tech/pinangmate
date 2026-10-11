import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/models/open_hours.dart';
import '../../data/models/plan.dart';
import '../../data/models/plan_generator.dart';
import '../../data/repositories/plan_repository.dart';
import '../auth/auth_view_model.dart';
import '../core/load_status.dart';

class PlanViewModel extends ChangeNotifier {
  PlanViewModel(this._repo, this._auth) {
    final n = nowWib();
    mulai = DateTime(n.year, n.month, n.day);
    _uid = _auth.user?.uid;
    _auth.addListener(_onAuth);
    muatData();
  }

  final PlanRepository _repo;
  final AuthViewModel _auth;
  String? _uid;
  bool _disposed = false;
  DateTime? _dimuatPada;

  // Isian form
  late DateTime mulai;
  int durasi = 3;
  int anggaran = 0; // 0 = tanpa batas
  final Set<Kategori> kategori = {
    Kategori.wisata,
    Kategori.kuliner,
    Kategori.penginapan,
  };
  final Set<String> minat = {};

  /// Tempat yang dipilih lewat tombol koper, didahulukan oleh algoritma.
  /// Urutan penambahan dipertahankan.
  final Map<String, Item> pilihan = {};

  // Data tempat
  LoadStatus status = LoadStatus.loading;
  List<Item> data = const [];
  List<String> tagWisata = const [];

  // Hasil
  Plan? plan;

  // Penyimpanan rencana yang sedang tampil
  bool menyimpan = false;
  bool tersimpan = false;
  String? pesanSimpan;
  String? errorSimpan;

  /// Ganti akun atau keluar: bersihkan draf supaya tidak bocor ke akun lain.
  void _onAuth() {
    final uid = _auth.user?.uid;
    if (uid == _uid) return;
    _uid = uid;
    pilihan.clear();
    plan = null;
    tersimpan = false;
    menyimpan = false;
    pesanSimpan = null;
    errorSimpan = null;
    _notify();
  }

  Future<void> muatData() async {
    status = LoadStatus.loading;
    _notify();
    try {
      data = await _repo.ambilSemuaAktif();
      tagWisata = _tagWisata(data);
      minat.retainAll(tagWisata.toSet());
      status = data.isEmpty ? LoadStatus.empty : LoadStatus.ready;
      _dimuatPada = DateTime.now();
    } catch (_) {
      status = LoadStatus.error;
    }
    _notify();
  }

  /// Muat ulang kalau datanya sudah lebih dari semenit.
  void segarkanJikaLama() {
    final t = _dimuatPada;
    if (t == null || DateTime.now().difference(t).inSeconds > 60) {
      muatData();
    }
  }

  List<String> _tagWisata(List<Item> items) {
    final set = <String>{};
    for (final i in items) {
      if (i.kategori == Kategori.wisata) set.addAll(i.tag);
    }
    return set.toList()..sort();
  }

  void setMulai(DateTime d) {
    mulai = DateTime(d.year, d.month, d.day);
    _notify();
  }

  void setDurasi(int d) {
    durasi = d < 1 ? 1 : (d > 14 ? 14 : d);
    _notify();
  }

  void setAnggaran(int a) {
    anggaran = a < 0 ? 0 : a;
    // Tidak memanggil notify: kolom teks sudah memegang nilainya.
  }

  void toggleKategori(Kategori k) {
    if (!kategori.remove(k)) kategori.add(k);
    _notify();
  }

  void toggleMinat(String tag) {
    if (!minat.remove(tag)) minat.add(tag);
    _notify();
  }

  // --- Tempat pilihan (tombol koper) ---

  bool dalamRencana(String id) => pilihan.containsKey(id);

  /// true kalau ditambahkan, false kalau dihapus. Jenis tempat otomatis
  /// ikut dicentang supaya tidak tersaring.
  bool toggleRencana(Item item) {
    if (pilihan.containsKey(item.id)) {
      pilihan.remove(item.id);
      _notify();
      return false;
    }
    pilihan[item.id] = item;
    kategori.add(item.kategori);
    _notify();
    return true;
  }

  /// Mengembalikan jumlah yang benar-benar baru ditambahkan.
  int tambahBanyak(Iterable<Item> items) {
    var baru = 0;
    for (final i in items) {
      if (pilihan.containsKey(i.id)) continue;
      pilihan[i.id] = i;
      kategori.add(i.kategori);
      baru++;
    }
    if (baru > 0) _notify();
    return baru;
  }

  void hapusDariRencana(String id) {
    if (pilihan.remove(id) != null) _notify();
  }

  void kosongkanPilihan() {
    if (pilihan.isEmpty) return;
    pilihan.clear();
    _notify();
  }

  /// Menyusun rencana dari isian form. false kalau belum bisa.
  bool susun() {
    if (kategori.isEmpty || status != LoadStatus.ready) return false;
    plan = buatRencana(
      PlanInput(
        mulai: mulai,
        durasi: durasi,
        anggaran: anggaran,
        kategori: Set.of(kategori),
        minat: kategori.contains(Kategori.wisata) ? Set.of(minat) : <String>{},
        prioritas: pilihan.keys.toSet(),
      ),
      data,
    );
    tersimpan = false;
    menyimpan = false;
    pesanSimpan = null;
    errorSimpan = null;
    _notify();
    return true;
  }

  /// Simpan rencana yang sedang tampil ke akun [uid]. true kalau berhasil
  /// (termasuk tersimpan di perangkat saat offline).
  Future<bool> simpan(String uid) async {
    final p = plan;
    if (p == null || tersimpan || menyimpan) return false;
    menyimpan = true;
    errorSimpan = null;
    pesanSimpan = null;
    _notify();
    try {
      await _repo.simpan(uid, p).timeout(const Duration(seconds: 8));
      tersimpan = true;
    } on TimeoutException {
      // Offline: tulisan sudah diantre di perangkat dan terkirim saat online.
      tersimpan = true;
      pesanSimpan = 'Tersimpan di perangkat. Akan disinkronkan saat online.';
    } catch (_) {
      errorSimpan = 'Gagal menyimpan. Coba lagi.';
    }
    menyimpan = false;
    _notify();
    return tersimpan;
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