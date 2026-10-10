import 'package:flutter/foundation.dart';

import '../../data/models/item.dart';
import '../../data/models/open_hours.dart';
import '../../data/models/plan.dart';
import '../../data/models/plan_generator.dart';
import '../../data/repositories/plan_repository.dart';
import '../core/load_status.dart';

class PlanViewModel extends ChangeNotifier {
  PlanViewModel(this._repo) {
    final n = nowWib();
    mulai = DateTime(n.year, n.month, n.day);
    muatData();
  }

  final PlanRepository _repo;
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

  // Data tempat
  LoadStatus status = LoadStatus.loading;
  List<Item> data = const [];
  List<String> tagWisata = const [];

  // Hasil
  Plan? plan;

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
      ),
      data,
    );
    _notify();
    return true;
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