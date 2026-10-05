import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../core/item_card.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'category_list_view_model.dart';

Kategori kategoriFromRoute(String? name) => Kategori.values.firstWhere(
      (k) => k.name == name,
      orElse: () => Kategori.wisata,
    );

String judulKategori(Kategori k) {
  switch (k) {
    case Kategori.wisata:
      return 'Wisata';
    case Kategori.penginapan:
      return 'Penginapan';
    case Kategori.kuliner:
      return 'Kuliner';
    case Kategori.event:
      return 'Event';
  }
}

class CategoryListPage extends StatelessWidget {
  const CategoryListPage({super.key, required this.kategori});

  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => CategoryListViewModel(c.read<ItemRepository>(), kategori),
      child: Scaffold(
        appBar: AppBar(title: Text(judulKategori(kategori))),
        body: Column(
          children: [
            _StickyFilter(kategori: kategori),
            Expanded(child: _Body(kategori: kategori)),
          ],
        ),
      ),
    );
  }
}

/// Di luar daftar, jadi tetap terlihat saat daftar digeser.
/// Kolom cari dan chip diaktifkan di state 7.
class _StickyFilter extends StatelessWidget {
  const _StickyFilter({required this.kategori});

  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText:
                        'Temukan ${judulKategori(kategori).toLowerCase()}…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (kategori == Kategori.wisata)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Chip(
                            label: const Text('Semua'),
                            backgroundColor: cs.primaryContainer,
                          ),
                          const SizedBox(width: 8),
                          const Chip(label: Text('Sejarah')),
                          const SizedBox(width: 8),
                          const Chip(label: Text('Alam')),
                          const SizedBox(width: 8),
                          const Chip(label: Text('Harga ▾')),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.kategori});

  final Kategori kategori;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryListViewModel>();
    return switch (vm.status) {
      LoadStatus.loading => const LoadingView(),
      LoadStatus.error => ErrorView(
          message: 'Gagal memuat data. Periksa koneksi lalu coba lagi.',
          onRetry: vm.retry,
        ),
      LoadStatus.empty => EmptyView(
          message:
              'Belum ada data ${judulKategori(kategori).toLowerCase()}.',
        ),
      LoadStatus.ready => ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: vm.items.length,
          itemBuilder: (context, i) {
            final item = vm.items[i];
            return ItemCard(
              item: item,
              onTap: () => context.push('/item/${item.id}'),
            );
          },
        ),
    };
  }
}