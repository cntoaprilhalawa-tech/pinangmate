import 'package:flutter_test/flutter_test.dart';
import 'package:pinangmate/data/models/item.dart';
import 'package:pinangmate/data/models/plan.dart';
import 'package:pinangmate/data/models/plan_codec.dart';
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

void main() {
  final data = [
    _item('w1', Kategori.wisata, 'Masjid', tag: ['sejarah']),
    _item('w2', Kategori.wisata, 'Pantai', harga: 15000, tag: ['alam']),
    _item('k1', Kategori.kuliner, 'Warung', harga: 20000, buka: '10:00', tutup: '20:00'),
    _item('h1', Kategori.penginapan, 'Hotel', harga: 300000, buka: '00:00', tutup: '23:59'),
  ];

  final plan = buatRencana(
    PlanInput(
      mulai: DateTime(2026, 12, 30),
      durasi: 3,
      kategori: {Kategori.wisata, Kategori.kuliner, Kategori.penginapan},
      minat: {'sejarah'},
    ),
    data,
  );

  test('kolom yang ditulis cocok dengan daftar di Firestore rules', () {
    final kolom = {...planToMap(plan).keys, 'createdAt'};
    expect(kolom, {
      'mulai', 'durasi', 'anggaran', 'kategori', 'minat', 'malam',
      'total', 'penginapan', 'hari', 'catatan', 'createdAt',
    });
  });

  test('durasi dan jumlah hari konsisten (syarat rules)', () {
    final m = planToMap(plan);
    expect(m['durasi'], 3);
    expect((m['hari'] as List).length, m['durasi']);
    expect(m['total'], isA<int>());
  });

  test('simpan lalu baca: isi rencana tetap sama, termasuk lintas tahun', () {
    final kembali = planFromMap(planToMap(plan));
    expect(kembali.total, plan.total);
    expect(kembali.malam, plan.malam);
    expect(kembali.penginapan?.itemId, plan.penginapan?.itemId);
    expect(kembali.hari.length, plan.hari.length);
    for (var i = 0; i < plan.hari.length; i++) {
      expect(kembali.hari[i].tanggal, plan.hari[i].tanggal);
      expect(
        kembali.hari[i].entries.map((e) => e.itemId).toList(),
        plan.hari[i].entries.map((e) => e.itemId).toList(),
      );
    }
    expect(kembali.hari.last.tanggal, DateTime(2027, 1, 1));
    expect(kembali.input.kategori, plan.input.kategori);
    expect(kembali.input.minat, {'sejarah'});
  });

  test('dokumen rusak tidak membuat aplikasi crash', () {
    expect(SavedPlan.tryParse('x', {'mulai': 123}), isNull);
  });
}