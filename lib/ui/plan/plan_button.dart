import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../auth/auth_view_model.dart';
import 'plan_view_model.dart';

/// Tombol koper: tambah atau hapus tempat dari rencana.
class PlanButton extends StatelessWidget {
  const PlanButton({super.key, required this.item, this.ukuran});

  final Item item;
  final Size? ukuran;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final plan = context.watch<PlanViewModel>();
    final cs = Theme.of(context).colorScheme;
    final ada = auth.loggedIn && plan.dalamRencana(item.id);

    return IconButton.outlined(
      tooltip: ada ? 'Hapus dari rencana' : 'Tambah ke rencana',
      style: ukuran == null ? null : IconButton.styleFrom(fixedSize: ukuran),
      icon: Icon(
        ada ? Icons.luggage : Icons.luggage_outlined,
        color: ada ? cs.primary : null,
      ),
      onPressed: () {
        if (!auth.loggedIn) {
          context.push('/login');
          return;
        }
        final messenger = ScaffoldMessenger.of(context);
        final router = GoRouter.of(context);
        final ditambah = plan.toggleRencana(item);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ditambah
                  ? '${item.nama} ditambahkan ke rencana.'
                  : '${item.nama} dihapus dari rencana.',
            ),
            action: ditambah
                ? SnackBarAction(
                    label: 'Lihat',
                    onPressed: () => router.go('/rencana'),
                  )
                : null,
          ),
        );
      },
    );
  }
}