import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/models/popular.dart';
import '../../data/repositories/item_repository.dart';
import '../auth/auth_view_model.dart';
import '../category/category_list_view_model.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'popular_card.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) =>
          CategoryListViewModel(c.read<ItemRepository>(), Kategori.wisata),
      child: const _BerandaView(),
    );
  }
}

class _BerandaView extends StatelessWidget {
  const _BerandaView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final nama = context.watch<AuthViewModel>().user?.displayName?.trim();
    final depan = (nama == null || nama.isEmpty) ? null : nama.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              depan == null ? 'Halo 👋' : 'Halo, $depan 👋',
              style: text.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              'Mau jalan-jalan ke mana hari ini?',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _CategoryGrid(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Populer minggu ini',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Geser ›',
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _PopularSection(),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _items = [
    (Icons.landscape_outlined, 'Wisata', 'wisata'),
    (Icons.hotel_outlined, 'Inap', 'penginapan'),
    (Icons.ramen_dining_outlined, 'Kuliner', 'kuliner'),
    (Icons.celebration_outlined, 'Event', 'event'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1, // bujur sangkar, tidak melar di layar lebar
              child: _CategoryTile(
                icon: _items[i].$1,
                label: _items[i].$2,
                jenis: _items[i].$3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.icon,
    required this.label,
    required this.jenis,
  });

  final IconData icon;
  final String label;
  final String jenis;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/kategori/$jenis'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: cs.onPrimaryContainer),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection();

  static const double _listHeight = 200;
  static const double _stateHeight = 240;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryListViewModel>();
    switch (vm.status) {
      case LoadStatus.loading:
        return const SizedBox(height: _stateHeight, child: LoadingView());
      case LoadStatus.error:
        return SizedBox(
          height: _stateHeight,
          child: ErrorView(
            message: 'Gagal memuat destinasi populer.',
            onRetry: vm.retry,
          ),
        );
      case LoadStatus.empty:
        return const SizedBox(
          height: _stateHeight,
          child: EmptyView(message: 'Belum ada destinasi populer.'),
        );
      case LoadStatus.ready:
        final list = popularItems(vm.all);
        return SizedBox(
          height: _listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (context, i) => const SizedBox(width: 12),
            itemBuilder: (context, i) => PopularCard(
              item: list[i],
              onTap: () => context.push('/item/${list[i].id}'),
            ),
          ),
        );
    }
  }
}