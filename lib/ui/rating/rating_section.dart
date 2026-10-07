import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/models/item.dart';
import '../../data/repositories/item_repository.dart';
import '../../data/repositories/rating_repository.dart';
import '../auth/auth_view_model.dart';
import '../core/formatters.dart';
import 'rating_view_model.dart';

/// Chip rata-rata nilai yang ikut berubah langsung saat ada yang menilai.
class RatingChip extends StatefulWidget {
  const RatingChip({super.key, required this.item});

  final Item item;

  @override
  State<RatingChip> createState() => _RatingChipState();
}

class _RatingChipState extends State<RatingChip> {
  late final Stream<Item?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = context.read<ItemRepository>().watchById(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Item?>(
      stream: _stream,
      builder: (context, snap) {
        final it = snap.data ?? widget.item;
        return Chip(
          avatar: const Icon(Icons.star_rounded, size: 18),
          label: Text(formatRating(it.ratingAvg, it.ratingCount)),
        );
      },
    );
  }
}

class RatingSection extends StatelessWidget {
  const RatingSection({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => RatingViewModel(
        c.read<RatingRepository>(),
        c.read<AuthViewModel>(),
        item.id,
      ),
      child: _SectionBody(item: item),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.item});

  final Item item;

  void _onTap(BuildContext context, AuthViewModel auth, RatingViewModel vm) {
    if (!auth.loggedIn) {
      context.push('/login');
      return;
    }
    vm.clearError();
    _showBeriNilai(context, vm, item.nama);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RatingViewModel>();
    final auth = context.watch<AuthViewModel>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final nilai = vm.nilai;

    final Widget status;
    if (!auth.loggedIn) {
      status = Text(
        'Masuk untuk memberi nilai.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    } else if (vm.loading) {
      status = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (nilai != null) {
      status = Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= nilai ? Icons.star_rounded : Icons.star_outline_rounded,
              color: cs.secondary,
            ),
          const SizedBox(width: 8),
          Text('Nilaimu: $nilai'),
        ],
      );
    } else {
      status = Text(
        'Kamu belum memberi nilai.',
        style: TextStyle(color: cs.onSurfaceVariant),
      );
    }

    final label = !auth.loggedIn
        ? 'Masuk untuk menilai'
        : (nilai == null ? 'Beri nilai' : 'Ubah nilai');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nilai tempat ini',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            status,
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: vm.loading ? null : () => _onTap(context, auth, vm),
                icon: const Icon(Icons.star_outline_rounded),
                label: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showBeriNilai(
  BuildContext context,
  RatingViewModel vm,
  String nama,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => ChangeNotifierProvider<RatingViewModel>.value(
      value: vm,
      child: _RatingSheet(nama: nama),
    ),
  );
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet({required this.nama});

  final String nama;

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  static const _label = ['', 'Buruk', 'Kurang', 'Cukup', 'Bagus', 'Sangat bagus'];

  late int _pilih;

  @override
  void initState() {
    super.initState();
    _pilih = context.read<RatingViewModel>().nilai ?? 0;
  }

  Future<void> _kirim() async {
    final vm = context.read<RatingViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await vm.submit(_pilih);
    if (!ok) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Terima kasih! Nilaimu tersimpan.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RatingViewModel>();
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Beri nilai',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.nama,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    iconSize: 40,
                    tooltip: '$i bintang',
                    onPressed: vm.saving ? null : () => setState(() => _pilih = i),
                    icon: Icon(
                      i <= _pilih
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: cs.secondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _pilih == 0 ? 'Pilih bintang' : _label[_pilih],
              style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(vm.error!, style: TextStyle(color: cs.error)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_pilih == 0 || vm.saving) ? null : _kirim,
                child: vm.saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(vm.nilai == null ? 'Kirim Nilai' : 'Perbarui Nilai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}