import 'dart:math' as math;

import 'item.dart';
import 'plan.dart';

const _slotWisataPagi = 8 * 60;
const _slotMakanSiang = 12 * 60;
const _slotWisataSore = 15 * 60;
const _slotMakanMalam = 18 * 60 + 30;
const _slotEvent = 19 * 60;

/// Selisih maksimal (menit) jam buka yang masih boleh digeser dari slot.
const _geserMaks = 120;

/// Porsi anggaran maksimal untuk penginapan.
const _batasPenginapan = 0.4;

typedef _Titik = ({double lat, double lng});

class _Slot {
  const _Slot(this.menit, this.kategori);

  final int menit;
  final Kategori kategori;
}

String _hhmm(int menit) {
  final h = (menit ~/ 60) % 24;
  final m = menit % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

int? _menit(String? hhmm) {
  if (hhmm == null) return null;
  final p = hhmm.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// Jarak dua titik dalam meter (rumus haversine).
double haversineMeter(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
}

DateTime _hariSaja(DateTime d) => DateTime(d.year, d.month, d.day);

/// Tanggal (tanpa jam) menurut WIB.
DateTime _hariWib(DateTime d) {
  final w = d.toUtc().add(const Duration(hours: 7));
  return DateTime(w.year, w.month, w.day);
}

bool _eventBeririsan(Item e, DateTime hari) {
  final a = e.tanggalMulai;
  final b = e.tanggalSelesai;
  if (a == null || b == null) return false;
  return !hari.isBefore(_hariWib(a)) && !hari.isAfter(_hariWib(b));
}

/// Nilai tertinggi, lalu penilai terbanyak, lalu nama.
int _prioritas(Item a, Item b) {
  final r = b.ratingAvg.compareTo(a.ratingAvg);
  if (r != 0) return r;
  final c = b.ratingCount.compareTo(a.ratingCount);
  if (c != 0) return c;
  return a.nama.compareTo(b.nama);
}

/// Penginapan: nilai tertinggi, lalu yang termurah.
int _prioritasInap(Item a, Item b) {
  final r = b.ratingAvg.compareTo(a.ratingAvg);
  if (r != 0) return r;
  final c = b.ratingCount.compareTo(a.ratingCount);
  if (c != 0) return c;
  final h = a.harga.compareTo(b.harga);
  if (h != 0) return h;
  return a.nama.compareTo(b.nama);
}

/// Jam (menit) tempat ini dikunjungi untuk slot tertentu, atau null kalau
/// tidak cocok. Kalau belum buka tapi bukanya tidak lebih dari 2 jam
/// setelah slot, jamnya digeser ke jam buka.
int? _jamUntukSlot(Item item, int slot) {
  final buka = _menit(item.jamBuka);
  var tutup = _menit(item.jamTutup);
  if (buka == null || tutup == null) return slot; // jam tidak diketahui
  if (tutup <= buka) tutup += 24 * 60; // lewat tengah malam, mis. 17:00-00:00
  if (slot >= buka && slot < tutup) return slot;
  if (slot < buka && buka - slot <= _geserMaks && buka < tutup) return buka;
  return null;
}

/// Ambil dari tiga kandidat teratas yang cocok jamnya, pilih yang paling
/// dekat dengan posisi sebelumnya.
({Item item, int menit})? _pilihUntukSlot(
  List<Item> sisa,
  int slot,
  _Titik? prev,
) {
  final kandidat = <(Item, int)>[];
  for (final it in sisa) {
    final jam = _jamUntukSlot(it, slot);
    if (jam != null) kandidat.add((it, jam));
    if (kandidat.length == 3) break;
  }
  if (kandidat.isEmpty) return null;
  var terbaik = kandidat.first;
  if (prev != null) {
    var jarakTerbaik = haversineMeter(
      prev.lat,
      prev.lng,
      terbaik.$1.lat,
      terbaik.$1.lng,
    );
    for (final k in kandidat.skip(1)) {
      final j = haversineMeter(prev.lat, prev.lng, k.$1.lat, k.$1.lng);
      if (j < jarakTerbaik) {
        terbaik = k;
        jarakTerbaik = j;
      }
    }
  }
  return (item: terbaik.$1, menit: terbaik.$2);
}

/// Empat langkah: hitung hari, saring, urutkan, bagi per hari + total biaya.
Plan buatRencana(PlanInput input, List<Item> semua) {
  final catatan = <String>[];
  final hari = math.min(14, math.max(1, input.durasi));
  final malam = hari - 1;
  final awal = _hariSaja(input.mulai);
  final tanggal = [
    for (var i = 0; i < hari; i++) DateTime(awal.year, awal.month, awal.day + i),
  ];
  final anggaran = input.anggaran < 0 ? 0 : input.anggaran;

  if (input.kategori.isEmpty) {
    return Plan(
      input: input,
      hari: [for (final t in tanggal) PlanDay(tanggal: t, entries: const [])],
      malam: malam,
      catatan: const ['Pilih minimal satu jenis (wisata, kuliner, event, atau penginapan).'],
    );
  }

  final aktif = semua.where((i) => i.aktif).toList();
  List<Item> dari(Kategori k) => aktif.where((i) => i.kategori == k).toList();

  // Penginapan: satu untuk seluruh perjalanan.
  PlanEntry? penginapan;
  if (input.kategori.contains(Kategori.penginapan)) {
    if (malam == 0) {
      catatan.add('Perjalanan 1 hari tidak perlu menginap.');
    } else {
      final kandidat = dari(Kategori.penginapan)..sort(_prioritasInap);
      if (kandidat.isEmpty) {
        catatan.add('Belum ada data penginapan.');
      } else {
        final batas =
            anggaran > 0 ? (anggaran * _batasPenginapan).floor() : null;
        Item? pilih;
        for (final p in kandidat) {
          if (batas == null || p.harga * malam <= batas) {
            pilih = p;
            break;
          }
        }
        if (pilih == null) {
          catatan.add(
            'Tidak ada penginapan yang muat sekitar 40% anggaran. '
            'Naikkan anggaran atau matikan Penginapan.',
          );
        } else {
          penginapan = PlanEntry(
            itemId: pilih.id,
            nama: pilih.nama,
            kategori: Kategori.penginapan,
            jam: '',
            biaya: pilih.harga,
            lat: pilih.lat,
            lng: pilih.lng,
          );
        }
      }
    }
  }

  final pakaiWisata = input.kategori.contains(Kategori.wisata);
  final pakaiKuliner = input.kategori.contains(Kategori.kuliner);
  final pakaiEvent = input.kategori.contains(Kategori.event);

  // Antrean wisata: yang cocok minat dulu, sisanya sebagai pengisi.
  var sisaWisata = <Item>[];
  if (pakaiWisata) {
    final semuaWisata = dari(Kategori.wisata);
    if (input.minat.isEmpty) {
      sisaWisata = semuaWisata..sort(_prioritas);
    } else {
      bool cocokMinat(Item i) => i.tag.any(input.minat.contains);
      final cocok = semuaWisata.where(cocokMinat).toList()..sort(_prioritas);
      final lain = semuaWisata.where((i) => !cocokMinat(i)).toList()
        ..sort(_prioritas);
      sisaWisata = [...cocok, ...lain];
      if (cocok.isEmpty) {
        catatan.add(
          'Tidak ada wisata dengan minat yang dipilih. Ditampilkan wisata lain.',
        );
      }
    }
  }

  final sisaKuliner = pakaiKuliner ? (dari(Kategori.kuliner)..sort(_prioritas)) : <Item>[];

  final sisaEvent = <Item>[];
  if (pakaiEvent) {
    sisaEvent.addAll(
      dari(Kategori.event).where((e) => tanggal.any((t) => _eventBeririsan(e, t))),
    );
    sisaEvent.sort(
      (a, b) => (a.tanggalMulai ?? DateTime(2100))
          .compareTo(b.tanggalMulai ?? DateTime(2100)),
    );
    if (sisaEvent.isEmpty) {
      catatan.add('Tidak ada event pada tanggal liburanmu.');
    }
  }

  final slots = <_Slot>[
    if (pakaiWisata) const _Slot(_slotWisataPagi, Kategori.wisata),
    if (pakaiKuliner) const _Slot(_slotMakanSiang, Kategori.kuliner),
    if (pakaiWisata) const _Slot(_slotWisataSore, Kategori.wisata),
    if (pakaiKuliner) const _Slot(_slotMakanMalam, Kategori.kuliner),
  ];

  // Bagi ke hari-hari.
  final hasilHari = <List<PlanEntry>>[];
  var kosongWisata = 0;
  var kosongKuliner = 0;
  final _Titik? awalHari = penginapan == null
      ? null
      : (lat: penginapan.lat, lng: penginapan.lng);

  for (final tgl in tanggal) {
    final entri = <PlanEntry>[];
    _Titik? posisi = awalHari;

    if (pakaiEvent) {
      for (var i = 0; i < sisaEvent.length; i++) {
        if (_eventBeririsan(sisaEvent[i], tgl)) {
          final e = sisaEvent.removeAt(i);
          entri.add(
            PlanEntry(
              itemId: e.id,
              nama: e.nama,
              kategori: Kategori.event,
              jam: _hhmm(_slotEvent),
              biaya: e.harga,
              lat: e.lat,
              lng: e.lng,
            ),
          );
          break; // satu event per hari
        }
      }
    }

    for (final s in slots) {
      final sumber = s.kategori == Kategori.wisata ? sisaWisata : sisaKuliner;
      final pilih = _pilihUntukSlot(sumber, s.menit, posisi);
      if (pilih == null) {
        if (s.kategori == Kategori.wisata) {
          kosongWisata++;
        } else {
          kosongKuliner++;
        }
        continue;
      }
      sumber.remove(pilih.item);
      entri.add(
        PlanEntry(
          itemId: pilih.item.id,
          nama: pilih.item.nama,
          kategori: s.kategori,
          jam: _hhmm(pilih.menit),
          biaya: pilih.item.harga,
          lat: pilih.item.lat,
          lng: pilih.item.lng,
        ),
      );
      posisi = (lat: pilih.item.lat, lng: pilih.item.lng);
    }

    entri.sort((a, b) => a.jam.compareTo(b.jam));
    hasilHari.add(entri);
  }

  if (kosongWisata > 0) {
    catatan.add(
      'Data wisata belum cukup atau tidak buka pada jamnya untuk $kosongWisata jadwal.',
    );
  }
  if (kosongKuliner > 0) {
    catatan.add(
      'Tidak ada kuliner yang buka pada jam makan untuk $kosongKuliner jadwal.',
    );
  }

  // Jaga anggaran: buang item berbiaya terbesar sampai muat.
  int hitungTotal() {
    var t = (penginapan?.biaya ?? 0) * malam;
    for (final h in hasilHari) {
      for (final e in h) {
        t += e.biaya;
      }
    }
    return t;
  }

  if (anggaran > 0) {
    while (hitungTotal() > anggaran) {
      int? hi;
      int? ei;
      var maks = 0;
      for (var h = 0; h < hasilHari.length; h++) {
        for (var e = 0; e < hasilHari[h].length; e++) {
          final b = hasilHari[h][e].biaya;
          if (b > 0 && b >= maks) {
            maks = b;
            hi = h;
            ei = e;
          }
        }
      }
      if (hi == null || ei == null) break;
      final dibuang = hasilHari[hi].removeAt(ei);
      catatan.add('Dihapus karena melebihi anggaran: ${dibuang.nama}.');
    }
    if (hitungTotal() > anggaran) {
      catatan.add('Anggaran belum cukup walau sudah dikurangi. Naikkan anggaran.');
    }
  }

  return Plan(
    input: input,
    hari: [
      for (var i = 0; i < tanggal.length; i++)
        PlanDay(tanggal: tanggal[i], entries: List.unmodifiable(hasilHari[i])),
    ],
    malam: malam,
    penginapan: penginapan,
    catatan: List.unmodifiable(catatan),
  );
}