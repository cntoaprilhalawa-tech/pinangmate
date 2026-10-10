import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_view_model.dart';
import '../../data/models/item.dart';
import '../../data/models/plan.dart';
import '../core/formatters.dart';
import '../core/state_views.dart';
import 'plan_format.dart';
import 'plan_view_model.dart';

class PlanResultPage extends StatelessWidget {
  const PlanResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PlanViewModel>();
    final plan = vm.plan;
    return Scaffold(
      appBar: AppBar(title: const Text('Rencanamu')),
      body: plan == null
          ? EmptyView(
              icon: Icons.luggage_outlined,
              message: 'Belum ada rencana. Susun dulu lewat form.',
              actionLabel: 'Susun Rencana',
              onAction: () => context.go('/rencana'),
            )
          : PlanBody(plan: plan),
      bottomNavigationBar: plan == null ? null : _SaveBar(vm: vm),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.vm});

  final PlanViewModel vm;

  Future<void> _simpan(BuildContext context) async {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.simpan(uid);
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.pesanSimpan ?? 'Rencana tersimpan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      color: cs.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (vm.errorSimpan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    vm.errorSimpan!,
                    style: TextStyle(color: cs.error),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: (vm.tersimpan || vm.menyimpan)
                          ? null
                          : () => _simpan(context),
                      child: vm.menyimpan
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(vm.tersimpan ? 'Tersimpan' : 'Simpan Rencana'),
                    ),
                  ),
                  if (vm.tersimpan) ...[
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => context.push('/rencana/tersimpan'),
                      child: const Text('Lihat'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _ikon(Kategori k) {
  switch (k) {
    case Kategori.wisata:
      return Icons.landscape_outlined;
    case Kategori.kuliner:
      return Icons.ramen_dining_outlined;
    case Kategori.event:
      return Icons.celebration_outlined;
    case Kategori.penginapan:
      return Icons.hotel_outlined;
  }
}

String _biayaLabel(PlanEntry e) {
  switch (e.kategori) {
    case Kategori.kuliner:
      return e.biaya > 0 ? 'mulai ${formatRupiah(e.biaya)}' : '-';
    case Kategori.penginapan:
      return '${formatRupiah(e.biaya)} / malam';
    case Kategori.wisata:
    case Kategori.event:
      return formatRupiah(e.biaya);
  }
}

class PlanBody extends StatelessWidget {
  const PlanBody({
    super.key,
    required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final awal = plan.hari.first.tanggal;
    final akhir = plan.hari.last.tanggal;
    final anggaran = plan.input.anggaran;
    final sisa = anggaran - plan.total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${rentangTanggal(awal, akhir)} · ${plan.hari.length} hari',
                  style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  rupiah(plan.total),
                  style: text.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  anggaran > 0
                      ? (sisa >= 0
                          ? 'dari anggaran ${rupiah(anggaran)} (sisa ${rupiah(sisa)})'
                          : 'melebihi anggaran ${rupiah(anggaran)} sebesar ${rupiah(-sisa)}')
                      : 'tanpa batas anggaran',
                  style: text.bodySmall?.copyWith(
                    color: sisa < 0 && anggaran > 0 ? cs.error : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimasi untuk 1 orang. Harga kuliner dan penginapan adalah harga mulai dari dan bisa berubah.',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        if (plan.catatan.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            color: cs.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in plan.catatan)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              size: 18, color: cs.onSecondaryContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c,
                              style: TextStyle(color: cs.onSecondaryContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (plan.penginapan != null) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Icon(_ikon(Kategori.penginapan)),
              title: Text(plan.penginapan!.nama),
              subtitle: Text(
                'Menginap ${plan.malam} malam · ${_biayaLabel(plan.penginapan!)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/item/${plan.penginapan!.itemId}'),
            ),
          ),
        ],
        for (var i = 0; i < plan.hari.length; i++) ...[
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              'Hari ${i + 1} · ${tanggalLengkap(plan.hari[i].tanggal)}',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (plan.hari[i].entries.isEmpty)
            Text(
              'Belum ada jadwal di hari ini.',
              style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            for (var j = 0; j < plan.hari[i].entries.length; j++)
              _TimelineTile(
                entry: plan.hari[i].entries[j],
                last: j == plan.hari[i].entries.length - 1,
                onTap: () => context
                    .push('/item/${plan.hari[i].entries[j].itemId}'),
              ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.tune),
          label: const Text('Ubah pengaturan'),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.entry,
    required this.last,
    required this.onTap,
  });

  final PlanEntry entry;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                entry.jam,
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 17),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: last ? Colors.transparent : cs.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(_ikon(entry.kategori), color: cs.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.nama,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _biayaLabel(entry),
                          style: text.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
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