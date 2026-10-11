import 'package:flutter_test/flutter_test.dart';
import 'package:pinangmate/data/models/item.dart';
import 'package:pinangmate/data/models/plan.dart';
import 'package:pinangmate/data/models/plan_generator.dart';

Item _item(
  String id,
  Kategori k,
  String nama, {
  int harga = 0,
  String? buka = '08:00',
  String? tutup = '17:00',
  List<String> tag = const [],
}) =>
    Item(
      id: id,
      kategori: k,
      nama: nama,
      harga: harga,
      jamBuka: buka,
      jamTutup: tutup,
      tag: tag,
      lat: 0.92,
      lng: 104.45,
    );

Iterable<PlanEntry> _semuaEntri(Plan p) => p.hari.expand((h) => h.entries);

void main() {
  test('favorit didahulukan walau tidak cocok minat', () {
    final data = [
      _item('w2', Kategori.wisata, 'Pantai', tag: ['alam']),
      _item('w5', Kategori.wisata, 'Gonggong', harga: 20000, tag: ['kota']),
      _item('w1', Kategori.wisata, 'Masjid', tag: ['sejarah']),
    ];
    final p = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 1,
        kategori: {Kategori.wisata},
        minat: {'alam'},
        prioritas: {'w5'},
      ),
      data,
    );
    expect(p.hari.first.entries.first.itemId, 'w5');
  });

  test('anggaran sempit: yang bukan favorit dibuang lebih dulu', () {
    final data = [
      _item('f', Kategori.wisata, 'Favorit', harga: 20000),
      _item('n', Kategori.wisata, 'Biasa', harga: 15000),
    ];
    final dengan = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 1,
        anggaran: 25000,
        kategori: {Kategori.wisata},
        prioritas: {'f'},
      ),
      data,
    );
    final idDengan = _semuaEntri(dengan).map((e) => e.itemId).toList();
    expect(idDengan, contains('f'));
    expect(idDengan, isNot(contains('n')));

    // Pembanding: tanpa favorit, yang termahal yang dibuang.
    final tanpa = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 1,
        anggaran: 25000,
        kategori: {Kategori.wisata},
      ),
      data,
    );
    final idTanpa = _semuaEntri(tanpa).map((e) => e.itemId).toList();
    expect(idTanpa, isNot(contains('f')));
  });

  test('favorit yang jenisnya tidak disertakan disebut di catatan', () {
    final data = [
      _item('w1', Kategori.wisata, 'Masjid'),
      _item('h', Kategori.penginapan, 'Hotel Favorit', harga: 300000,
          buka: '00:00', tutup: '23:59'),
    ];
    final p = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 2,
        kategori: {Kategori.wisata},
        prioritas: {'h'},
      ),
      data,
    );
    expect(p.penginapan, isNull);
    expect(p.catatan.any((c) => c.contains('Hotel Favorit')), isTrue);
  });
}