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

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key, required this.kategori});

  final Kategori kategori;

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kategori = widget.kategori;
    return ChangeNotifierProvider(
      create: (c) => CategoryListViewModel(c.read<ItemRepository>(), kategori),
      child: Scaffold(
        appBar: AppBar(title: Text(judulKategori(kategori))),
        body: Column(
          children: [
            _StickyFilter(kategori: kategori, search: _search),
            Expanded(child: _Body(kategori: kategori, search: _search)),
          ],
        ),
      ),
    );
  }
}

/// Di luar daftar, jadi tetap terlihat saat daftar digeser.
class _StickyFilter extends StatelessWidget {
  const _StickyFilter({required this.kategori, required this.search});

  final Kategori kategori;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryListViewModel>();
    final cs = Theme.of(context).colorScheme;
    final tags = vm.tags;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: search,
                  onChanged: vm.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText:
                        'Temukan ${judulKategori(kategori).toLowerCase()}…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: vm.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Hapus pencarian',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              search.clear();
                              vm.setQuery('');
                            },
                          ),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: vm.tag == null,
                          onSelected: (_) => vm.setTag(null),
                        ),
                        for (final t in tags) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(_cap(t)),
                            selected: vm.tag == t,
                            onSelected: (_) => vm.setTag(t),
                          ),
                        ],
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            vm.harga == HargaFilter.semua
                                ? 'Harga ▾'
                                : '${vm.harga.label} ▾',
                          ),
                          selected: vm.harga != HargaFilter.semua,
                          onSelected: (_) => _pilihHarga(context, vm),
                        ),
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

  void _pilihHarga(BuildContext context, CategoryListViewModel vm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final h in HargaFilter.values)
              ListTile(
                title: Text(h.label),
                trailing: vm.harga == h ? const Icon(Icons.check) : null,
                onTap: () {
                  vm.setHarga(h);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.kategori, required this.search});

  final Kategori kategori;
  final TextEditingController search;

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
          message: 'Belum ada data ${judulKategori(kategori).toLowerCase()}.',
        ),
      LoadStatus.ready => _Hasil(vm: vm, search: search),
    };
  }
}

class _Hasil extends StatelessWidget {
  const _Hasil({required this.vm, required this.search});

  final CategoryListViewModel vm;
  final TextEditingController search;

  @override
  Widget build(BuildContext context) {
    final list = vm.filtered;
    if (list.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        message: 'Tidak ada hasil yang cocok.',
        actionLabel: vm.filterAktif ? 'Reset filter' : null,
        onAction: vm.filterAktif
            ? () {
                search.clear();
                vm.reset();
              }
            : null,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final item = list[i];
        return ItemCard(
          item: item,
          onTap: () => context.push('/item/${item.id}'),
        );
      },
    );
  }
}