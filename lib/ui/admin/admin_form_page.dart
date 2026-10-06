import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_view_model.dart' show PickedLocation;
import 'package:image_picker/image_picker.dart';
import '../../data/models/foto_codec.dart';
import '../core/item_card.dart' show ItemPhoto;
import '../../data/models/form_parsers.dart';
import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../category/category_list_page.dart' show judulKategori;
import '../core/formatters.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'admin_form_view_model.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _fmtTime(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

TimeOfDay? _parseTime(String? s) {
  if (s == null) return null;
  final p = s.split(':');
  if (p.length != 2) return null;
  final h = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  if (h == null || m == null) return null;
  return TimeOfDay(hour: h, minute: m);
}

/// Tanggal (tanpa jam) menurut WIB dari waktu tersimpan.
DateTime _wibDate(DateTime d) {
  final w = d.toUtc().add(const Duration(hours: 7));
  return DateTime(w.year, w.month, w.day);
}

DateTime _wibStart(DateTime d) =>
    DateTime.utc(d.year, d.month, d.day).subtract(const Duration(hours: 7));

DateTime _wibEnd(DateTime d) => DateTime.utc(d.year, d.month, d.day, 23, 59)
    .subtract(const Duration(hours: 7));

String _hargaLabel(Kategori k) {
  switch (k) {
    case Kategori.wisata:
      return 'Harga tiket (Rp), kosongkan jika gratis';
    case Kategori.penginapan:
      return 'Harga mulai dari per malam (Rp)';
    case Kategori.kuliner:
      return 'Harga mulai dari per porsi (Rp)';
    case Kategori.event:
      return 'Harga tiket (Rp), kosongkan jika tidak ada';
  }
}

InputDecoration _dec(String label, {String? helper, Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperMaxLines: 3,
    suffixIcon: suffix,
    border: const OutlineInputBorder(),
  );
}

class AdminFormPage extends StatelessWidget {
  const AdminFormPage({super.key, this.id, required this.kategori});

  final String? id;
  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AdminFormViewModel(
        c.read<ItemRepository>(),
        id: id,
        kategori: kategori,
      ),
      child: const _FormScaffold(),
    );
  }
}

class _FormScaffold extends StatelessWidget {
  const _FormScaffold();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFormViewModel>();
    final judul =
        '${vm.isEdit ? 'Ubah' : 'Tambah'} ${judulKategori(vm.kategori)}';
    return Scaffold(
      appBar: AppBar(title: Text(judul)),
      body: switch (vm.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error =>
          ErrorView(message: 'Gagal memuat data.', onRetry: vm.load),
        LoadStatus.empty => const EmptyView(message: 'Data tidak ditemukan.'),
        LoadStatus.ready =>
          _ItemForm(initial: vm.item, kategori: vm.kategori),
      },
    );
  }
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({required this.initial, required this.kategori});

  final Item? initial;
  final Kategori kategori;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _key = GlobalKey<FormState>();

  late final TextEditingController _nama;
  late final TextEditingController _deskripsi;
  late final TextEditingController _harga;
  late final TextEditingController _jamBuka;
  late final TextEditingController _jamTutup;
  late final TextEditingController _mulai;
  late final TextEditingController _selesai;
  late final TextEditingController _koordinat;
  late final TextEditingController _alamat;
  late final TextEditingController _kontak;
  late final TextEditingController _sumber;
  late final TextEditingController _tag;

  late bool _aktif;
  DateTime? _mulaiDate;
  DateTime? _selesaiDate;
    String? _foto;
  bool _memproses = false;

  bool get _isEvent => widget.kategori == Kategori.event;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _nama = TextEditingController(text: i?.nama ?? '');
    _deskripsi = TextEditingController(text: i?.deskripsi ?? '');
    _harga = TextEditingController(
      text: (i != null && i.harga > 0) ? '${i.harga}' : '',
    );
    _jamBuka = TextEditingController(text: i?.jamBuka ?? '');
    _jamTutup = TextEditingController(text: i?.jamTutup ?? '');
    _mulaiDate =
        i?.tanggalMulai == null ? null : _wibDate(i!.tanggalMulai!);
    _selesaiDate =
        i?.tanggalSelesai == null ? null : _wibDate(i!.tanggalSelesai!);
    _mulai = TextEditingController(
      text: _mulaiDate == null ? '' : formatTanggal(_mulaiDate!),
    );
    _selesai = TextEditingController(
      text: _selesaiDate == null ? '' : formatTanggal(_selesaiDate!),
    );
    _koordinat = TextEditingController(
      text: i == null ? '' : formatKoordinat(i.lat, i.lng),
    );
    _alamat = TextEditingController(text: i?.alamat ?? '');
    _kontak = TextEditingController(text: i?.kontak ?? '');
    _sumber = TextEditingController(text: i?.sumber ?? '');
    _tag = TextEditingController(text: i?.tag.join(', ') ?? '');
    _aktif = i?.aktif ?? true;
        _foto = i?.foto;
  }

  @override
  void dispose() {
    for (final c in [
      _nama, _deskripsi, _harga, _jamBuka, _jamTutup, _mulai, _selesai,
      _koordinat, _alamat, _kontak, _sumber, _tag,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihJam(TextEditingController c) async {
    final awal = _parseTime(c.text) ?? const TimeOfDay(hour: 8, minute: 0);
    final t = await showTimePicker(
      context: context,
      initialTime: awal,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => c.text = _fmtTime(t));
  }

  Future<void> _pilihTanggal({required bool awal}) async {
    final hariIni = _wibDate(DateTime.now());
    final saatIni = awal ? _mulaiDate : _selesaiDate;
    final d = await showDatePicker(
      context: context,
      initialDate: saatIni ?? hariIni,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    setState(() {
      if (awal) {
        _mulaiDate = d;
        _mulai.text = formatTanggal(d);
      } else {
        _selesaiDate = d;
        _selesai.text = formatTanggal(d);
      }
    });
  }

  Future<void> _tempelKoordinat() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() => _koordinat.text = text);
  }
    Future<void> _pilihDiPeta() async {
    final k = parseKoordinat(_koordinat.text);
    final hasil = await context.push<PickedLocation>(
      '/admin/lokasi',
      extra: k == null ? null : LatLng(k.lat, k.lng),
    );
    if (hasil == null || !mounted) return;
    setState(() {
      _koordinat.text = formatKoordinat(hasil.lat, hasil.lng);
      if (_alamat.text.trim().isEmpty && hasil.alamat != null) {
        _alamat.text = hasil.alamat!;
      }
    });
  }
    Future<void> _pilihFoto() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _memproses = true);
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 60,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 200 * 1024) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Foto masih terlalu besar setelah dikompres. Pilih foto lain (JPEG).',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _foto = encodeFoto(bytes));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal memilih foto.')),
      );
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  void _hapusFoto() => setState(() => _foto = null);

  Future<void> _simpan() async {
    if (!_key.currentState!.validate()) return;
    final k = parseKoordinat(_koordinat.text)!;
    final vm = context.read<AdminFormViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final i = widget.initial;

    String? opsional(String s) {
      final t = s.trim();
      return t.isEmpty ? null : t;
    }

    final item = Item(
      id: i?.id ?? '',
      kategori: widget.kategori,
      nama: _nama.text.trim(),
      deskripsi: _deskripsi.text.trim(),
      harga: int.tryParse(_harga.text.trim()) ?? 0,
      jamBuka: _isEvent ? null : opsional(_jamBuka.text),
      jamTutup: _isEvent ? null : opsional(_jamTutup.text),
      kontak: opsional(_kontak.text),
      alamat: opsional(_alamat.text),
      lat: k.lat,
      lng: k.lng,
      foto: _foto,
      sumber: opsional(_sumber.text),
      aktif: _aktif,
      tanggalMulai: _isEvent ? _wibStart(_mulaiDate!) : null,
      tanggalSelesai: _isEvent ? _wibEnd(_selesaiDate!) : null,
      tag: parseTag(_tag.text),
    );

    final ok = await vm.save(item);
    if (!mounted || !ok) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${item.nama} disimpan.')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminFormViewModel>();
    final cs = Theme.of(context).colorScheme;
    const gap = SizedBox(height: 16);

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _key,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                                ItemPhoto(foto: _foto, width: double.infinity, height: 180),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _memproses ? null : _pilihFoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(_foto == null ? 'Pilih foto' : 'Ganti foto'),
                      ),
                    ),
                    if (_foto != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _hapusFoto,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    'Foto dikompres otomatis (maksimal sekitar 200 KB) dan disimpan di database.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                gap,
                TextFormField(
                  controller: _nama,
                  textCapitalization: TextCapitalization.words,
                  decoration: _dec('Nama'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Nama minimal 3 huruf'
                      : null,
                ),
                                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pilihDiPeta,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pilih di peta / cari lokasi'),
                  ),
                ),
                gap,
                TextFormField(
                  controller: _deskripsi,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _dec('Deskripsi'),
                ),
                gap,
                TextFormField(
                  controller: _harga,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _dec(_hargaLabel(widget.kategori)),
                ),
                gap,
                if (_isEvent) ...[
                  TextFormField(
                    controller: _mulai,
                    readOnly: true,
                    onTap: () => _pilihTanggal(awal: true),
                    decoration:
                        _dec('Tanggal mulai', suffix: const Icon(Icons.event)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  gap,
                  TextFormField(
                    controller: _selesai,
                    readOnly: true,
                    onTap: () => _pilihTanggal(awal: false),
                    decoration: _dec('Tanggal selesai',
                        suffix: const Icon(Icons.event)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi';
                      if (_mulaiDate != null &&
                          _selesaiDate != null &&
                          _selesaiDate!.isBefore(_mulaiDate!)) {
                        return 'Tanggal selesai sebelum tanggal mulai';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _jamBuka,
                          readOnly: true,
                          onTap: () => _pilihJam(_jamBuka),
                          decoration: _dec('Jam buka',
                              suffix: const Icon(Icons.schedule)),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _jamTutup,
                          readOnly: true,
                          onTap: () => _pilihJam(_jamTutup),
                          decoration: _dec('Jam tutup',
                              suffix: const Icon(Icons.schedule)),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Buka 24 jam: isi 00:00 sampai 23:59',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
                gap,
                TextFormField(
                  controller: _koordinat,
                  keyboardType: TextInputType.text,
                  decoration: _dec(
                    'Koordinat (lat, lng)',
                    helper:
                        'Di Google Maps tekan lama titiknya, salin angka koordinat, lalu tempel. Contoh: 0.929444, 104.420389',
                    suffix: IconButton(
                      tooltip: 'Tempel dari clipboard',
                      icon: const Icon(Icons.content_paste),
                      onPressed: _tempelKoordinat,
                    ),
                  ),
                  validator: (v) => parseKoordinat(v ?? '') == null
                      ? 'Format salah. Contoh: 0.929444, 104.420389'
                      : null,
                ),
                gap,
                TextFormField(
                  controller: _alamat,
                  decoration: _dec('Alamat'),
                ),
                gap,
                TextFormField(
                  controller: _kontak,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(
                    'Kontak (telepon / WhatsApp)',
                    helper: 'Dipakai tombol Hubungi Penyedia. Boleh kosong.',
                  ),
                ),
                gap,
                TextFormField(
                  controller: _sumber,
                  keyboardType: TextInputType.url,
                  decoration: _dec('Sumber informasi'),
                ),
                gap,
                TextFormField(
                  controller: _tag,
                  decoration: _dec(
                    'Tag (pisahkan dengan koma)',
                    helper:
                        'Dipakai untuk filter dan rekomendasi. Contoh: sejarah, religi',
                  ),
                ),
                gap,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  subtitle: const Text('Matikan untuk menyembunyikan dari pengunjung'),
                  value: _aktif,
                  onChanged: (v) => setState(() => _aktif = v),
                ),
              ],
            ),
          ),
        ),
        Material(
          elevation: 3,
          color: cs.surface,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (vm.saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        vm.saveError!,
                        style: TextStyle(color: cs.error),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: vm.saving ? null : _simpan,
                      child: vm.saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}