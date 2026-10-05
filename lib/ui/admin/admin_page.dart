import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../category/category_list_page.dart' show judulKategori;
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'admin_list_view_model.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: Kategori.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Admin'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final k in Kategori.values) Tab(text: judulKategori(k)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final k in Kategori.values) _AdminList(kategori: k),
          ],
        ),
      ),
    );
  }
}

class _AdminList extends StatelessWidget {
  const _AdminList({required this.kategori});

  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => AdminListViewModel(c.read<ItemRepository>(), kategori),
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/admin/form?kategori=${kategori.name}'),
          icon: const Icon(Icons.add),
          label: const Text('Tambah'),
        ),
        body: _Body(kategori: kategori),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.kategori});

  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminListViewModel>();
    return switch (vm.status) {
      LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorView(
          message: 'Gagal memuat data. Periksa koneksi lalu coba lagi.',
          onRetry: vm.retry,
        ),
      LoadStatus.empty => EmptyView(
          message: 'Belum ada data ${judulKategori(kategori).toLowerCase()}.',
        ),
      LoadStatus.ready => ListView.separated(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: vm.items.length,
          separatorBuilder: (context, i) => const Divider(height: 1),
          itemBuilder: (context, i) => _AdminTile(item: vm.items[i]),
        ),
    };
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final alamat = item.alamat ?? '—';
    return ListTile(
      leading: Icon(
        item.aktif ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      title: Text(item.nama, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.aktif ? alamat : 'Nonaktif · $alamat',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => context.push('/admin/form?id=${item.id}'),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'ubah') context.push('/admin/form?id=${item.id}');
          if (v == 'hapus') _hapus(context, item);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'ubah', child: Text('Ubah')),
          PopupMenuItem(value: 'hapus', child: Text('Hapus')),
        ],
      ),
    );
  }
}

Future<void> _hapus(BuildContext context, Item item) async {
  final repo = context.read<ItemRepository>();
  final messenger = ScaffoldMessenger.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus data?'),
      content: Text('"${item.nama}" akan dihapus permanen.'),
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
  if (ok != true) return;
  try {
    await repo.delete(item.id);
    messenger.showSnackBar(SnackBar(content: Text('${item.nama} dihapus.')));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Gagal menghapus. Cek izin admin.')),
    );
  }
}