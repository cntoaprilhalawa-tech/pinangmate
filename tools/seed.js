const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const key = require('C:/secrets/pinangmate-key.json');

initializeApp({ credential: cert(key) });
const db = getFirestore();

const base = { kategori: 'wisata', harga: 0, aktif: true, ratingSum: 0, ratingCount: 0 };

const items = [
  {
    id: 'masjid-raya-sultan-riau',
    nama: 'Masjid Raya Sultan Riau',
    deskripsi: 'Masjid bersejarah di Pulau Penyengat yang direnovasi tahun 1832, terkenal dengan warna kuning-hijau, 13 kubah, dan cerita putih telur sebagai campuran bahan bangunannya.',
    jamBuka: '08:00', jamTutup: '17:00',
    lat: 0.929444, lng: 104.420389,
    tag: ['sejarah', 'religi'],
    alamat: 'Kampung Jambat, Pulau Penyengat',
    sumber: 'https://en.wikipedia.org/wiki/Grand_Mosque_of_the_Sultan_of_Riau',
  },
  {
    id: 'vihara-avalokitesvara-graha',
    nama: 'Vihara Avalokitesvara Graha',
    deskripsi: 'Vihara besar di Tanjung Unggat yang diresmikan tahun 2009, menyimpan patung Dewi Kuan Yin duduk setinggi 16,8 meter. Terbuka untuk semua pengunjung.',
    jamBuka: '09:00', jamTutup: '16:00',
    lat: 0.947901, lng: 104.512116,
    tag: ['religi'],
    alamat: 'Jl. WR Supratman Km 14, Tanjung Unggat',
    sumber: 'https://id.wikipedia.org/wiki/Wihara_Avalokitesvara_Graha',
  },
  {
    id: 'museum-sultan-sulaiman-badrul-alamsyah',
    nama: 'Museum Sultan Sulaiman Badrul Alamsyah',
    deskripsi: 'Museum kota di bekas gedung sekolah masa kolonial yang menyimpan lebih dari 2.600 koleksi sejarah dan budaya Melayu. Tutup hari Senin dan libur nasional.',
    jamBuka: '09:00', jamTutup: '15:00',
    lat: 0.92925, lng: 104.444,
    tag: ['sejarah'],
    alamat: 'Jl. Ketapang No. 2, Kemboja',
    sumber: 'https://id.wikipedia.org/wiki/Museum_Sultan_Sulaiman_Badrul_Alamsyah',
  },
  {
    id: 'gedung-gonggong',
    nama: 'Gedung Gonggong',
    deskripsi: 'Bangunan ikon Tanjungpinang berbentuk siput gonggong di kawasan Tepi Laut, cocok untuk menikmati senja dengan latar Pulau Penyengat.',
    jamBuka: '09:00', jamTutup: '20:00',
    lat: 0.9273, lng: 104.4382,
    tag: ['kota'],
    alamat: 'Kawasan Laman Boenda, Tepi Laut',
    sumber: 'https://id.wikipedia.org/wiki/Gedung_Gonggong',
  },
  {
    // aktif:false dan lat/lng sementara; ganti setelah titik aslinya diambil dari Google Maps
    id: 'pantai-impian',
    nama: 'Pantai Impian',
    deskripsi: 'Pantai di Tanjungpinang Barat yang menghadap Pulau Dompak, tempat santai menikmati senja dan kuliner tepi pantai.',
    jamBuka: '00:00', jamTutup: '23:59',
    lat: 0.9, lng: 104.4,
    tag: ['alam'],
    alamat: 'Jl. Pantai Impian, Tanjungpinang Barat',
    sumber: 'https://id.wikipedia.org/wiki/Pantai_Impian',
    aktif: false,
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