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