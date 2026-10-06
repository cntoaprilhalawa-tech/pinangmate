import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/item_card.dart';
import '../core/load_status.dart';
import '../core/state_views.dart';
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
        LoadStatus.ready => ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: vm.items.length,
            itemBuilder: (context, i) {
              final item = vm.items[i];
              return ItemCard(
                item: item,
                onTap: () => context.push('/item/${item.id}'),
              );
            },
          ),
      },
    );
  }
}