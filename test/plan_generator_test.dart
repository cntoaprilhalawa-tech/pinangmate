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
  double lat = 0.92,
  double lng = 104.45,
  int sum = 0,
  int count = 0,
  DateTime? mulai,
  DateTime? selesai,
}) =>
    Item(
      id: id,
      kategori: k,
      nama: nama,
      harga: harga,
      jamBuka: buka,
      jamTutup: tutup,
      tag: tag,
      lat: lat,
      lng: lng,
      ratingSum: sum,
      ratingCount: count,
      tanggalMulai: mulai,
      tanggalSelesai: selesai,
    );

final _data = <Item>[
  _item('w1', Kategori.wisata, 'Masjid', tag: ['sejarah', 'religi'], sum: 10, count: 2),
  _item('w2', Kategori.wisata, 'Pantai', harga: 15000, tag: ['alam'], lat: 0.90, lng: 104.44, buka: '00:00', tutup: '23:59'),
  _item('w3', Kategori.wisata, 'Benteng', tag: ['sejarah']),
  _item('w4', Kategori.wisata, 'Museum', tag: ['sejarah'], buka: '09:00', tutup: '15:00'),
  _item('w5', Kategori.wisata, 'Gonggong', harga: 20000, tag: ['kota']),
  _item('k1', Kategori.kuliner, 'Akau', harga: 10000, buka: '17:00', tutup: '00:00', tag: ['kuliner']),
  _item('k2', Kategori.kuliner, 'Warung Siang', harga: 20000, buka: '10:00', tutup: '15:00'),
  _item('h1', Kategori.penginapan, 'Hotel Mahal', harga: 700000, buka: '00:00', tutup: '23:59'),
  _item('h2', Kategori.penginapan, 'Hotel Murah', harga: 200000, buka: '00:00', tutup: '23:59'),
  // 10 Des 00:00 WIB sampai 12 Des 23:59 WIB (ditulis dalam UTC agar tidak
  // bergantung zona waktu mesin).
  _item('e1', Kategori.event, 'Festival', buka: null, tutup: null,
      mulai: DateTime.utc(2026, 12, 9, 17), selesai: DateTime.utc(2026, 12, 12, 16, 59)),
];

Iterable<PlanEntry> _semuaEntri(Plan p) => p.hari.expand((h) => h.entries);

void main() {
  test('jarak: 1 derajat bujur di khatulistiwa sekitar 111 km', () {
    expect(haversineMeter(0, 104, 0, 105), closeTo(111195, 300));
    expect(haversineMeter(0.9, 104.4, 0.9, 104.4), 0);
  });

  test('anggaran kecil: tidak ada penginapan yang muat dan total tidak melebihi anggaran', () {
    final p = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 2,
        anggaran: 50000,
        kategori: {Kategori.wisata, Kategori.kuliner, Kategori.penginapan},
      ),
      _data,
    );
    expect(p.penginapan, isNull);
    expect(p.total, lessThanOrEqualTo(50000));
    expect(p.catatan.any((c) => c.contains('penginapan')), isTrue);
  });

  test('durasi panjang: tidak ada tempat yang diulang dan ada catatan data kurang', () {
    final p = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 5, kategori: {Kategori.wisata}),
      _data,
    );
    final ids = _semuaEntri(p).map((e) => e.itemId).toList();
    expect(ids.toSet().length, ids.length);
    expect(ids.length, lessThanOrEqualTo(5));
    expect(p.catatan.any((c) => c.contains('wisata')), isTrue);
  });

  test('minat: wisata yang cocok tag dipakai lebih dulu', () {
    final p = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 1,
        kategori: {Kategori.wisata},
        minat: {'alam'},
      ),
      _data,
    );
    expect(p.hari.first.entries.first.itemId, 'w2');
  });

  test('penginapan hanya muncul kalau dicentang, dan dihitung per malam', () {
    final tanpa = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 3, kategori: {Kategori.wisata}),
      _data,
    );
    expect(tanpa.penginapan, isNull);

    final dengan = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 3,
        kategori: {Kategori.wisata, Kategori.penginapan},
      ),
      _data,
    );
    expect(dengan.penginapan?.itemId, 'h2'); // nilai sama, pilih yang termurah
    expect(dengan.malam, 2);
    expect(dengan.biayaPenginapan, 400000);
  });

  test('perjalanan 1 hari tidak menginap', () {
    final p = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 1, kategori: {Kategori.penginapan}),
      _data,
    );
    expect(p.penginapan, isNull);
    expect(p.catatan.any((c) => c.contains('1 hari')), isTrue);
  });

  test('tidak ada jenis yang dipilih: rencana kosong dengan catatan', () {
    final p = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 2, kategori: <Kategori>{}),
      _data,
    );
    expect(p.kosong, isTrue);
    expect(p.catatan, isNotEmpty);
  });

  test('jam buka: museum bergeser ke 09:00 untuk slot pagi dan tidak dipasang sore', () {
    final museum = _data.where((i) => i.id == 'w4').toList();
    final p = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 1, kategori: {Kategori.wisata}),
      museum,
    );
    expect(p.hari.first.entries.length, 1);
    expect(p.hari.first.entries.first.jam, '09:00');
  });

  test('kuliner yang baru buka sore hanya dipasang untuk makan malam', () {
    final akau = _data.where((i) => i.id == 'k1').toList();
    final p = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 1), durasi: 1, kategori: {Kategori.kuliner}),
      akau,
    );
    expect(p.hari.first.entries.single.jam, '18:30');
  });

  test('event: hanya kalau dicentang dan tanggalnya beririsan', () {
    final dengan = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 9), durasi: 3, kategori: {Kategori.event}),
      _data,
    );
    expect(_semuaEntri(dengan).single.itemId, 'e1');
    expect(dengan.hari[1].entries.single.jam, '19:00'); // 10 Des, hari kedua

    final tanpa = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 9), durasi: 3, kategori: {Kategori.wisata}),
      _data,
    );
    expect(_semuaEntri(tanpa).any((e) => e.kategori == Kategori.event), isFalse);

    final luar = buatRencana(
      PlanInput(mulai: DateTime(2026, 12, 20), durasi: 2, kategori: {Kategori.event}),
      _data,
    );
    expect(luar.catatan.any((c) => c.contains('event')), isTrue);
  });

  test('total = jumlah biaya semua entri + penginapan x malam', () {
    final p = buatRencana(
      PlanInput(
        mulai: DateTime(2026, 12, 1),
        durasi: 3,
        kategori: {Kategori.wisata, Kategori.kuliner, Kategori.penginapan},
      ),
      _data,
    );
    final manual = _semuaEntri(p).fold<int>(0, (s, e) => s + e.biaya) +
        (p.penginapan?.biaya ?? 0) * p.malam;
    expect(p.total, manual);
  });
}