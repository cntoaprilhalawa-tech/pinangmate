import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/plan_codec.dart';
import '../../data/repositories/plan_repository.dart';
import '../auth/auth_view_model.dart';
import '../category/category_list_page.dart' show judulKategori;
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'plan_format.dart';
import 'plan_result_page.dart' show PlanBody;
import 'saved_plans_view_model.dart';

Future<bool> _konfirmasiHapus(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus rencana?'),
      content: const Text('Rencana ini akan dihapus permanen.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  return ok == true;
}

String _judul(SavedPlan s) {
  final h = s.plan.hari;
  if (h.isEmpty) return 'Rencana liburan';
  return rentangTanggal(h.first.tanggal, h.last.tanggal);
}

class SavedPlansPage extends StatelessWidget {
  const SavedPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rencana tersimpan')),
        body: const EmptyView(message: 'Masuk dulu untuk melihat rencanamu.'),
      );
    }
    return ChangeNotifierProvider(
      create: (c) => SavedPlansViewModel(c.read<PlanRepository>(), uid),
      child: Scaffold(
        appBar: AppBar(title: const Text('Rencana tersimpan')),
        body: const _ListBody(),
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  const _ListBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavedPlansViewModel>();
    return switch (vm.status) {
      LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorView(
          message: 'Gagal memuat rencana. Periksa koneksi lalu coba lagi.',
          onRetry: vm.retry,
        ),
      LoadStatus.empty => EmptyView(
          icon: Icons.bookmarks_outlined,
          message: 'Belum ada rencana tersimpan.',
          actionLabel: 'Susun Rencana',
          onAction: () => context.go('/rencana'),
        ),
      LoadStatus.ready => ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: vm.items.length,
          itemBuilder: (context, i) {
            final s = vm.items[i];
            final jenis = s.plan.input.kategori.map(judulKategori).join(', ');
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.luggage_outlined),
                title: Text(_judul(s)),
                subtitle: Text(
                  '${s.plan.hari.length} hari · ${rupiah(s.plan.total)}\n$jenis',
                ),
                isThreeLine: true,
                onTap: () => context.push('/rencana/tersimpan/${s.id}'),
                trailing: IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    if (!await _konfirmasiHapus(context)) return;
                    final ok = await vm.hapus(s.id);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Rencana dihapus.' : 'Gagal menghapus rencana.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
    };
  }
}

class SavedPlanPage extends StatefulWidget {
  const SavedPlanPage({super.key, required this.id});

  final String id;

  @override
  State<SavedPlanPage> createState() => _SavedPlanPageState();
}

class _SavedPlanPageState extends State<SavedPlanPage> {
  late Future<SavedPlan?> _future;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthViewModel>().user?.uid;
    _muat();
  }

  void _muat() {
    final uid = _uid;
    _future = uid == null
        ? Future<SavedPlan?>.value(null)
        : context.read<PlanRepository>().ambil(uid, widget.id);
  }

  Future<void> _hapus() async {
    final uid = _uid;
    if (uid == null) return;
    final repo = context.read<PlanRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    if (!await _konfirmasiHapus(context)) return;
    try {
      await repo.hapus(uid, widget.id).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Offline: dihapus saat online.
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal menghapus rencana.')),
      );
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Rencana dihapus.')));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SavedPlan?>(
      future: _future,
      builder: (context, snap) {
        final saved = snap.data;
        final Widget body;
        if (snap.connectionState != ConnectionState.done) {
          body = const LoadingView();
        } else if (snap.hasError) {
          body = ErrorView(
            message: 'Gagal memuat rencana. Periksa koneksi lalu coba lagi.',
            onRetry: () => setState(_muat),
          );
        } else if (saved == null) {
          body = const EmptyView(message: 'Rencana tidak ditemukan.');
        } else {
          body = PlanBody(plan: saved.plan);
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rencana tersimpan'),
            actions: [
              if (saved != null)
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _hapus,
                ),
            ],
          ),
          body: body,
        );
      },
    );
  }
}