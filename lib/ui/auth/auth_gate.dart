import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_view_model.dart';

/// Menampilkan [child] hanya kalau sudah login.
/// Tamu melihat ajakan masuk.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthViewModel>().loggedIn;
    if (loggedIn) return child;

    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.luggage_outlined, size: 48, color: cs.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Simpan perjalananmu',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Masuk supaya rencana dan favoritmu tersimpan di akun.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Masuk / Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet ajakan masuk untuk tamu (wireframe halaman 8).
Future<void> showAjakanMasuk(BuildContext context, {VoidCallback? onLater}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.luggage_outlined, size: 40),
          const SizedBox(height: 8),
          Text(
            'Simpan perjalananmu',
            style: Theme.of(ctx)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Masuk supaya rencana dan favoritmu tersimpan di akun.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/login');
              },
              child: const Text('Masuk / Daftar'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onLater?.call();
            },
            child: const Text('Nanti saja'),
          ),
        ],
      ),
    ),
  );
}