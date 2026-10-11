import 'package:flutter_test/flutter_test.dart';
import 'package:pinangmate/data/models/item.dart';
import 'package:pinangmate/data/models/item_search.dart';

Item _item(
  String id,
  Kategori k,
  String nama, {
  String deskripsi = '',
  String? alamat,
  List<String> tag = const [],
}) =>
    Item(
      id: id,
      kategori: k,
      nama: nama,
      deskripsi: deskripsi,
      alamat: alamat,
      tag: tag,
      lat: 0.92,
      lng: 104.45,
    );

void main() {
  final data = [
    _item('1', Kategori.wisata, 'Masjid Raya', tag: ['sejarah'], alamat: 'Pulau Penyengat'),
    _item('2', Kategori.wisata, 'Museum', deskripsi: 'Koleksi sejarah Melayu'),
    _item('3', Kategori.kuliner, 'Akau Potong Lembu', alamat: 'Jl. Potong Lembu'),
    _item('4', Kategori.penginapan, 'Hotel Sejarah Inn'),
  ];

  test('kata kunci kosong tidak menghasilkan apa-apa', () {
    expect(cariItem(data, ''), isEmpty);
    expect(cariItem(data, '   '), isEmpty);
  });

  test('tidak peka huruf besar-kecil dan mencari di nama, alamat, tag, deskripsi', () {
    expect(cariItem(data, 'PENYENGAT').map((e) => e.id), ['1']);
    expect(cariItem(data, 'potong').map((e) => e.id), ['3']);
    expect(cariItem(data, 'koleksi').map((e) => e.id), ['2']);
  });

  test('nama yang cocok didahulukan, sisanya urut nama', () {
    expect(cariItem(data, 'sejarah').map((e) => e.id), ['4', '1', '2']);
  });

  test('filter kategori', () {
    expect(
      cariItem(data, 'sejarah', kategori: Kategori.wisata).map((e) => e.id),
      ['1', '2'],
    );
  });
}