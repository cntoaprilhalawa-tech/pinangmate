const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const key = require('C:/secrets/pinangmate-key.json');

initializeApp({ credential: cert(key) });
const db = getFirestore();

const base = { harga: 0, aktif: true, ratingSum: 0, ratingCount: 0 };
const wib = (s) => Timestamp.fromDate(new Date(s)); // tulis tanggal dengan +07:00

const items = [
  // ---------- PENGINAPAN ----------
  {
    id: 'aston-tanjung-pinang',
    kategori: 'penginapan',
    nama: 'Aston Tanjung Pinang Hotel & Conference Center',
    deskripsi: 'Hotel bintang empat di Jl. Adisucipto, sekitar tiga menit berkendara dari Bandara Raja Haji Fisabilillah. Tersedia kolam renang luar ruangan dan sarapan.',
    harga: 740000, // harga mulai dari per malam, bisa berubah
    jamBuka: '00:00', jamTutup: '23:59',
    lat: 0.915264, lng: 104.51876,
    tag: ['hotel'],
    alamat: 'Jl. Adisucipto Km 11, Tanjungpinang',
    sumber: 'Tripadvisor dan tiket.com (harga mulai dari, bisa berubah)',
  },

  // ---------- KULINER ----------
  {
    id: 'akau-potong-lembu',
    kategori: 'kuliner',
    nama: 'Akau Potong Lembu',
    deskripsi: 'Pusat kuliner terbuka legendaris yang ramai di malam hari, terkenal dengan seafood seperti sop ikan, ikan bakar, cumi, dan gonggong.',
    harga: 10000, // mulai dari per porsi (kisaran Rp 10.000 - 100.000)
    jamBuka: '17:00', jamTutup: '00:00',
    lat: 0.927774, lng: 104.448955,
    tag: ['kuliner', 'seafood'],
    alamat: 'Jl. Potong Lembu No. 98, Kemboja, Tanjungpinang Barat',
    sumber: 'https://disbudpar.tanjungpinangkota.go.id/destinasi-detail/akau-potong-lembu',
  },

  // ---------- EVENT (semua sudah lewat; titik peta PERKIRAAN) ----------
  {
    id: 'kemilau-nusantara-kepri-2026',
    kategori: 'event',
    nama: 'Kemilau Nusantara Kepri 2026',
    deskripsi: 'Festival budaya tahunan di kawasan Laman Gurindam XII, depan Gedung LAM Tanjungpinang, bertema Pulau Penyengat Jembatan Lintas Generasi. Ada parade budaya, tari kreasi, dan musik tradisional Melayu.',
    tanggalMulai: wib('2026-06-13T00:00:00+07:00'),
    tanggalSelesai: wib('2026-06-15T23:59:00+07:00'),
    lat: 0.9273, lng: 104.4382, // perkiraan: sekitar Gedung Gonggong
    tag: ['event', 'budaya'],
    alamat: 'Laman Gurindam XII, depan Gedung LAM Tanjungpinang (titik peta perkiraan)',
    sumber: 'https://kepriprov.go.id/berita/pemprov-kepri/dua-event-pariwisata-unggulan-kepri-2026-kemilau-nusantara-dan-penyengat-heritage-siap-digelar',
  },
  {
    id: 'penyengat-heritage-2026',
    kategori: 'event',
    nama: 'Penyengat Heritage 2026',
    deskripsi: 'Rangkaian kegiatan budaya, edukasi sejarah, dan seni tradisional di halaman Balai Adat Pulau Penyengat, termasuk festival gasing, tari kreasi, dan bazar.',
    tanggalMulai: wib('2026-06-19T00:00:00+07:00'),
    tanggalSelesai: wib('2026-06-21T23:59:00+07:00'),
    lat: 0.929444, lng: 104.420389, // perkiraan: sekitar Masjid Raya Sultan Riau
    tag: ['event', 'budaya', 'sejarah'],
    alamat: 'Balai Adat Pulau Penyengat (titik peta perkiraan)',
    sumber: 'https://kepriprov.go.id/berita/pemprov-kepri/dua-event-pariwisata-unggulan-kepri-2026-kemilau-nusantara-dan-penyengat-heritage-siap-digelar',
  },
  {
    id: 'festival-kopi-merdeka-2026',
    kategori: 'event',
    nama: 'Festival Kopi Merdeka 2026',
    deskripsi: 'Festival edisi kelima di kawasan Kota Lama Tanjungpinang yang memadukan bazar kopi, UMKM, pertunjukan seni budaya, dan penampilan musisi.',
    tanggalMulai: wib('2026-08-20T00:00:00+07:00'),
    tanggalSelesai: wib('2026-08-23T23:59:00+07:00'),
    lat: 0.927774, lng: 104.448955, // perkiraan: pusat kota, ganti dengan titik Jalan Merdeka
    tag: ['event', 'kuliner'],
    alamat: 'Jalan Merdeka, Kota Lama Tanjungpinang (titik peta perkiraan)',
    sumber: 'https://primetimes.id/2026/07/30/sederet-artis-papan-atas-akan-meriahkan-festival-kopi-merdeka-2026-di-kota-tanjungpinang/',
  },
];

(async () => {
  for (const { id, ...data } of items) {
    await db.collection('items').doc(id).set({
      ...base,
      ...data,
      updatedAt: FieldValue.serverTimestamp(),
    });
    console.log('OK', id);
  }
  process.exit(0);
})();