import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';
import 'wishlist_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.itemId,
    this.outlined = false,
    this.ukuran,
  });

  final String itemId;

  /// Gaya berbingkai untuk dipasang di bar bawah.
  final bool outlined;

  /// Ukuran tetap tombol. Kosong = ukuran bawaan.
  final Size? ukuran;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final wish = context.watch<WishlistViewModel>();
    final fav = auth.loggedIn && wish.isFav(itemId);
    final cs = Theme.of(context).colorScheme;

    final tooltip = fav ? 'Hapus dari wishlist' : 'Simpan ke wishlist';
    final icon = Icon(
      fav ? Icons.favorite : Icons.favorite_border,
      color: fav ? cs.error : null,
    );
    final style = ukuran == null
        ? null
        : IconButton.styleFrom(fixedSize: ukuran);

    Future<void> onPressed() async {
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
    }

    return outlined
        ? IconButton.outlined(
            tooltip: tooltip,
            icon: icon,
            style: style,
            onPressed: onPressed,
          )
        : IconButton(
            tooltip: tooltip,
            icon: icon,
            style: style,
            onPressed: onPressed,
          );
  }
}