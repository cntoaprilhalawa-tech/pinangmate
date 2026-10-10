import 'item.dart';

class PlanInput {
  const PlanInput({
    required this.mulai,
    required this.durasi,
    this.anggaran = 0,
    this.kategori = const {Kategori.wisata, Kategori.kuliner},
    this.minat = const {},
  });

  /// Tanggal berangkat.
  final DateTime mulai;

  /// Jumlah hari (1 sampai 14).
  final int durasi;

  /// Rupiah. 0 = tanpa batas.
  final int anggaran;

  /// Jenis yang disertakan.
  final Set<Kategori> kategori;

  /// Tag minat wisata (huruf kecil). Kosong = semua wisata.
  final Set<String> minat;
}

class PlanEntry {
  const PlanEntry({
    required this.itemId,
    required this.nama,
    required this.kategori,
    required this.jam,
    required this.biaya,
    required this.lat,
    required this.lng,
  });

  final String itemId;
  final String nama;
  final Kategori kategori;

  /// 'HH:mm'. Kosong untuk penginapan.
  final String jam;
  final int biaya;
  final double lat;
  final double lng;
}

class PlanDay {
  const PlanDay({required this.tanggal, required this.entries});

  final DateTime tanggal;
  final List<PlanEntry> entries;
}

class Plan {
  const Plan({
    required this.input,
    required this.hari,
    required this.malam,
    this.penginapan,
    this.catatan = const [],
  });

  final PlanInput input;
  final List<PlanDay> hari;
  final int malam;

  /// Biaya per malam ada di [PlanEntry.biaya].
  final PlanEntry? penginapan;

  /// Peringatan dan penjelasan untuk pengguna.
  final List<String> catatan;

  int get biayaPenginapan => (penginapan?.biaya ?? 0) * malam;

  int get total =>
      hari.fold<int>(
        0,
        (s, d) => s + d.entries.fold<int>(0, (a, e) => a + e.biaya),
      ) +
      biayaPenginapan;

  bool get kosong =>
      penginapan == null && hari.every((d) => d.entries.isEmpty);
}