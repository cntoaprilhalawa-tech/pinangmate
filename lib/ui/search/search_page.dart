import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/repositories/plan_repository.dart';
import '../category/category_list_page.dart' show judulKategori;
import '../core/item_card.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'search_view_model.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => SearchViewModel(c.read<PlanRepository>()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: vm.setQuery,
          decoration: const InputDecoration(
            hintText: 'Temukan destinasi…',
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (vm.query.isNotEmpty)
            IconButton(
              tooltip: 'Hapus pencarian',
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                vm.setQuery('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: vm.kategori == null,
                  onSelected: (_) => vm.setKategori(null),
                ),
                for (final k in Kategori.values) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(judulKategori(k)),
                    selected: vm.kategori == k,
                    onSelected: (_) => vm.setKategori(k),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: _Hasil()),
        ],
      ),
    );
  }
}

class _Hasil extends StatelessWidget {
  const _Hasil();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    switch (vm.status) {
      case LoadStatus.loading:
        return const LoadingView();
      case LoadStatus.error:
        return ErrorView(
          message: 'Gagal memuat data. Periksa koneksi lalu coba lagi.',
          onRetry: vm.muat,
        );
      case LoadStatus.empty:
        return const EmptyView(message: 'Belum ada data untuk dicari.');
      case LoadStatus.ready:
        break;
    }

    if (!vm.adaQuery) {
      return const EmptyView(
        icon: Icons.search,
        message:
            'Ketik nama tempat, alamat, atau minat, misalnya "sejarah".',
      );
    }
    final hasil = vm.hasil;
    if (hasil.isEmpty) {
      return EmptyView(
        icon: Icons.search_off,
        message: 'Tidak ada hasil untuk "${vm.query.trim()}".',
      );
    }

    final grup = <Kategori, List<Item>>{};
    for (final i in hasil) {
      grup.putIfAbsent(i.kategori, () => []).add(i);
    }
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final anak = <Widget>[];
    for (final k in Kategori.values) {
      final list = grup[k];
      if (list == null) continue;
      anak.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            '${judulKategori(k)} (${list.length})',
            style: text.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      );
      for (final item in list) {
        anak.add(
          ItemCard(
            item: item,
            onTap: () => context.push('/item/${item.id}'),
          ),
        );
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: anak,
    );
  }
}