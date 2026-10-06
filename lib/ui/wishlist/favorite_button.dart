import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import 'wishlist_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final wish = context.watch<WishlistViewModel>();
    final fav = auth.loggedIn && wish.isFav(itemId);
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: fav ? 'Hapus dari wishlist' : 'Simpan ke wishlist',
      icon: Icon(
        fav ? Icons.favorite : Icons.favorite_border,
        color: fav ? cs.error : null,
      ),
      onPressed: () async {
        if (!auth.loggedIn) {
          context.push('/login');
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        final ok = await wish.toggle(itemId);
        if (!ok) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Gagal memperbarui wishlist.')),
          );
        }
      },
    );
  }
}