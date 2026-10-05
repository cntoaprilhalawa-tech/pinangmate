import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../core/formatters.dart';
import '../core/item_card.dart';
import '../core/item_labels.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
import 'item_detail_view_model.dart';

class ItemDetailPage extends StatelessWidget {
  const ItemDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ItemDetailViewModel(c.read<ItemRepository>(), id),
      child: const _DetailBody(),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ItemDetailViewModel>();
    switch (vm.status) {
      case LoadStatus.loading:
        return Scaffold(appBar: AppBar(), body: const LoadingView());
      case LoadStatus.error:
        return Scaffold(
          appBar: AppBar(),
          body: ErrorView(
            message: 'Gagal memuat data. Periksa koneksi lalu coba lagi.',
            onRetry: vm.load,
          ),
        );
      case LoadStatus.empty:
        return Scaffold(
          appBar: AppBar(),
          body: const EmptyView(message: 'Data tidak ditemukan.'),
        );
      case LoadStatus.ready:
        return _DetailContent(item: vm.item!);
    }
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isEvent = item.kategori == Kategori.event;
    final hasJam = !isEvent && item.jamBuka != null && item.jamTutup != null;
    final tanggal = tanggalLabel(item);
    final harga = hargaLabel(item);

    final footer = <String>[
      if (item.updatedAt != null)
        'Diperbarui ${formatTanggal(item.updatedAt!)}',
      if (item.sumber != null) 'Sumber: ${item.sumber}',
    ].join(' · ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: ItemPhoto(
                foto: item.foto,
                width: double.infinity,
                height: 220,
                radius: 0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nama,
                    style: text.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(Icons.star_rounded, size: 18),
                        label: Text(
                          formatRating(item.ratingAvg, item.ratingCount),
                        ),
                      ),
                      if (tanggal != null)
                        Chip(
                          avatar: const Icon(Icons.event, size: 18),
                          label: Text(tanggal),
                        ),
                      if (isEvent && tanggal != null)
                        Chip(label: EventBadge(item: item)),
                      if (hasJam)
                        Chip(
                          avatar: const Icon(Icons.schedule, size: 18),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OpenBadge(
                                jamBuka: item.jamBuka,
                                jamTutup: item.jamTutup,
                              ),
                              Text(' ${item.jamBuka}–${item.jamTutup}'),
                            ],
                          ),
                        ),
                      if (harga != null)
                        Chip(
                          avatar: const Icon(Icons.sell_outlined, size: 18),
                          label: Text(harga),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (item.deskripsi.isNotEmpty)
                    Text(item.deskripsi, style: text.bodyLarge),
                  if (item.alamat != null) ...[
                    const SizedBox(height: 16),
                    _InfoRow(icon: Icons.place_outlined, text: item.alamat!),
                  ],
                  if (item.kontak != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.call_outlined, text: item.kontak!),
                  ],
                  if (footer.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      footer,
                      style: text.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}