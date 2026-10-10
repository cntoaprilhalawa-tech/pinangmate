import '../core/formatters.dart';

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bln = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String namaHari(DateTime d) => _hari[d.weekday - 1];

/// 'Selasa, 1 Des 2026'
String tanggalLengkap(DateTime d) => '${namaHari(d)}, ${formatTanggal(d)}';

/// '1–3 Des 2026', '30 Nov – 2 Des 2026', atau satu tanggal bila sehari.
String rentangTanggal(DateTime a, DateTime b) {
  if (a.year == b.year && a.month == b.month) {
    if (a.day == b.day) return formatTanggal(a);
    return '${a.day}–${b.day} ${_bln[a.month - 1]} ${a.year}';
  }
  if (a.year == b.year) {
    return '${a.day} ${_bln[a.month - 1]} – ${b.day} ${_bln[b.month - 1]} ${a.year}';
  }
  return '${formatTanggal(a)} – ${formatTanggal(b)}';
}

String rupiah(int v) => v <= 0 ? 'Rp 0' : formatRupiah(v);