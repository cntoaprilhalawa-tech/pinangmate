import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../category/category_list_page.dart' show judulKategori;
import '../core/item_card.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import '../plan/plan_view_model.dart';
import 'wishlist_view_model.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WishlistViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: switch (vm.status) {
        LoadStatus.loading => const LoadingView(),
        LoadStatus.error => ErrorView(
            message: 'Gagal memuat wishlist. Periksa koneksi lalu coba lagi.',
            onRetry: vm.retry,
          ),
        LoadStatus.empty => EmptyView(
            icon: Icons.favorite_border,
            message:
                'Belum ada favorit. Tekan ikon hati pada tempat yang kamu suka.',
            actionLabel: 'Jelajahi wisata',
            onAction: () => context.go('/kategori/wisata'),
          ),
        LoadStatus.ready => _Ready(vm: vm),
      },
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.vm});

  final WishlistViewModel vm;

  void _tambahKeRencana(BuildContext context, List<Item> tampil) {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final baru = context.read<PlanViewModel>().tambahBanyak(tampil);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          baru > 0
              ? '$baru tempat ditambahkan ke rencana.'
              : 'Semua favorit ini sudah ada di rencana.',
        ),
        action: SnackBarAction(
          label: 'Lihat',
          onPressed: () => router.go('/rencana'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tampil = vm.tampil;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Semua (${vm.items.length})'),
                selected: vm.kategoriFilter == null,
                onSelected: (_) => vm.setFilter(null),
              ),
              for (final k in Kategori.values)
                if (vm.jumlah(k) > 0) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${judulKategori(k)} (${vm.jumlah(k)})'),
                    selected: vm.kategoriFilter == k,
                    onSelected: (_) => vm.setFilter(k),
                  ),
                ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tampil.isEmpty
              ? const EmptyView(message: 'Tidak ada favorit untuk jenis ini.')
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: tampil.length,
                  itemBuilder: (context, i) {
                    final item = tampil[i];
                    return ItemCard(
                      item: item,
                      onTap: () => context.push('/item/${item.id}'),
                    );
                  },
                ),
        ),
        Material(
          elevation: 3,
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: tampil.isEmpty
                    ? null
                    : () => _tambahKeRencana(context, tampil),
                icon: const Icon(Icons.luggage_outlined),
                label: Text('Tambahkan ${tampil.length} favorit ke rencana'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}