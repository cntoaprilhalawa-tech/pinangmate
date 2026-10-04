import 'package:cloud_firestore/cloud_firestore.dart';

enum Kategori { wisata, penginapan, kuliner, event }

class Item {
  final String id;
  final Kategori kategori;
  final String nama;
  final String deskripsi;
  final int harga;
  final String? jamBuka; // format 'HH:mm'
  final String? jamTutup;
  final String? kontak;
  final String? alamat;
  final double lat;
  final double lng;
  final String? foto; // tautan atau teks base64 kecil
  final String? sumber;
  final bool aktif;
  final DateTime? updatedAt;
  final DateTime? tanggalMulai; // khusus event
  final DateTime? tanggalSelesai;
  final List<String> tag; // minat: sejarah, alam, dll.
  final int ratingSum;
  final int ratingCount;

  const Item({
    required this.id,
    required this.kategori,
    required this.nama,
    this.deskripsi = '',
    this.harga = 0,
    this.jamBuka,
    this.jamTutup,
    this.kontak,
    this.alamat,
    required this.lat,
    required this.lng,
    this.foto,
    this.sumber,
    this.aktif = true,
    this.updatedAt,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.tag = const [],
    this.ratingSum = 0,
    this.ratingCount = 0,
  });

  double get ratingAvg => ratingCount == 0 ? 0 : ratingSum / ratingCount;

  factory Item.fromMap(String id, Map<String, dynamic> m) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Item(
      id: id,
      kategori: Kategori.values.firstWhere(
        (k) => k.name == m['kategori'],
        orElse: () => Kategori.wisata,
      ),
      nama: m['nama'] ?? '',
      deskripsi: m['deskripsi'] ?? '',
      harga: (m['harga'] as num?)?.toInt() ?? 0,
      jamBuka: m['jamBuka'],
      jamTutup: m['jamTutup'],
      kontak: m['kontak'],
      alamat: m['alamat'],
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      foto: m['foto'],
      sumber: m['sumber'],
      aktif: m['aktif'] ?? true,
      updatedAt: ts(m['updatedAt']),
      tanggalMulai: ts(m['tanggalMulai']),
      tanggalSelesai: ts(m['tanggalSelesai']),
      tag: List<String>.from(m['tag'] ?? const []),
      ratingSum: (m['ratingSum'] as num?)?.toInt() ?? 0,
      ratingCount: (m['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'kategori': kategori.name,
        'nama': nama,
        'deskripsi': deskripsi,
        'harga': harga,
        'jamBuka': jamBuka,
        'jamTutup': jamTutup,
        'kontak': kontak,
        'alamat': alamat,
        'lat': lat,
        'lng': lng,
        'foto': foto,
        'sumber': sumber,
        'aktif': aktif,
        'updatedAt': FieldValue.serverTimestamp(),
        'tanggalMulai': tanggalMulai == null ? null : Timestamp.fromDate(tanggalMulai!),
        'tanggalSelesai': tanggalSelesai == null ? null : Timestamp.fromDate(tanggalSelesai!),
        'tag': tag,
        'ratingSum': ratingSum,
        'ratingCount': ratingCount,
      };
}