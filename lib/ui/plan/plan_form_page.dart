import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../category/category_list_page.dart' show judulKategori;

import '../core/load_status.dart';
import 'plan_format.dart';
import 'plan_view_model.dart';

const _urutan = [
  Kategori.wisata,
  Kategori.kuliner,
  Kategori.event,
  Kategori.penginapan,
];

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class PlanFormPage extends StatefulWidget {
  const PlanFormPage({super.key});

  @override
  State<PlanFormPage> createState() => _PlanFormPageState();
}

class _PlanFormPageState extends State<PlanFormPage> {
  final _anggaran = TextEditingController();

  @override
  void initState() {
    super.initState();
    final vm = context.read<PlanViewModel>();
    if (vm.anggaran > 0) _anggaran.text = '${vm.anggaran}';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) vm.segarkanJikaLama();
    });
  }

  @override
  void dispose() {
    _anggaran.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal(PlanViewModel vm) async {
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    final d = await showDatePicker(
      context: context,
      initialDate: vm.mulai.isBefore(hariIni) ? hariIni : vm.mulai,
      firstDate: hariIni,
      lastDate: DateTime(hariIni.year + 2, hariIni.month, hariIni.day),
    );
    if (d != null) vm.setMulai(d);
  }

  void _susun(PlanViewModel vm) {
    if (vm.susun()) context.push('/rencana/hasil');
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanViewModel>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pulang = DateTime(
      vm.mulai.year,
      vm.mulai.month,
      vm.mulai.day + vm.durasi - 1,
    );

    final siap = vm.status == LoadStatus.ready && vm.kategori.isNotEmpty;
    final label = vm.status == LoadStatus.loading
        ? 'Memuat data…'
        : vm.kategori.isEmpty
            ? 'Pilih minimal satu jenis'
            : 'Susun Rencana';

    Widget judul(String t) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            t,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        );

    return Scaffold(
           appBar: AppBar(
        title: const Text('Susun Rencana'),
        actions: [
          IconButton(
            tooltip: 'Rencana tersimpan',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => context.push('/rencana/tersimpan'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                judul('Tanggal berangkat'),
                OutlinedButton.icon(
                  onPressed: () => _pilihTanggal(vm),
                  icon: const Icon(Icons.event),
                  label: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tanggalLengkap(vm.mulai)),
                  ),
                ),
                judul('Durasi'),
                Row(
                  children: [
                    IconButton.outlined(
                      tooltip: 'Kurangi hari',
                      onPressed:
                          vm.durasi > 1 ? () => vm.setDurasi(vm.durasi - 1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${vm.durasi} hari',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Tambah hari',
                      onPressed:
                          vm.durasi < 14 ? () => vm.setDurasi(vm.durasi + 1) : null,
                      icon: const Icon(Icons.add),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Pulang ${tanggalLengkap(pulang)}',
                        style: text.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                judul('Anggaran'),
                TextField(
                  controller: _anggaran,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) => vm.setAnggaran(int.tryParse(v) ?? 0),
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: '0',
                    helperText: 'Kosongkan atau isi 0 untuk tanpa batas',
                    border: OutlineInputBorder(),
                  ),
                ),
                judul('Sertakan'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in _urutan)
                      FilterChip(
                        label: Text(judulKategori(k)),
                        selected: vm.kategori.contains(k),
                        onSelected: (_) => vm.toggleKategori(k),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Matikan Penginapan kalau kamu sudah punya tempat menginap atau tinggal di sini.',
                    style:
                        text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
                if (vm.kategori.contains(Kategori.wisata) &&
                    vm.tagWisata.isNotEmpty) ...[
                  judul('Minat wisata'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in vm.tagWisata)
                        FilterChip(
                          label: Text(_cap(t)),
                          selected: vm.minat.contains(t),
                          onSelected: (_) => vm.toggleMinat(t),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Kosongkan untuk semua wisata.',
                      style: text.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
                if (vm.status == LoadStatus.error)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: cs.error),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Gagal memuat data tempat.'),
                        ),
                        TextButton(
                          onPressed: vm.muatData,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                if (vm.status == LoadStatus.empty)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Belum ada data tempat untuk disusun.'),
                  ),
              ],
            ),
          ),
          Material(
            elevation: 3,
            color: cs.surface,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.onSecondary,
                    ),
                    onPressed: siap ? () => _susun(vm) : null,
                    child: Text(label),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}