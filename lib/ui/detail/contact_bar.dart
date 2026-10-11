import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../core/launchers.dart';
import '../plan/plan_button.dart';
import '../wishlist/favorite_button.dart';

class ContactBar extends StatelessWidget {
  const ContactBar({super.key, required this.item});

  final Item item;

  /// Tinggi semua tombol (sama supaya sejajar).
  static const double _tinggi = 52;

  /// Lebar tombol hati dan koper.
  static const double _lebarIkon = 52;

  @override
  Widget build(BuildContext context) {
    final kontak = item.kontak?.trim();
    final ada = kontak != null && kontak.isNotEmpty;
    const ukuranIkon = Size(_lebarIkon, _tinggi);
    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: _tinggi,
                  child: FilledButton.icon(
                    onPressed: ada ? () => _pilih(context, kontak) : null,
                    icon: const Icon(Icons.call_outlined),
                    label: Text(
                      ada ? 'Hubungi Penyedia' : 'Kontak belum tersedia',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FavoriteButton(
                itemId: item.id,
                outlined: true,
                ukuran: ukuranIkon,
              ),
              const SizedBox(width: 8),
              PlanButton(item: item, ukuran: ukuranIkon),
            ],
          ),
        ),
      ),
    );
  }

  void _pilih(BuildContext context, String kontak) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Telepon'),
              subtitle: Text(kontak),
              onTap: () {
                Navigator.pop(ctx);
                teleponPenyedia(context, kontak);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('WhatsApp'),
              subtitle: Text(kontak),
              onTap: () {
                Navigator.pop(ctx);
                whatsappPenyedia(context, kontak);
              },
            ),
          ],
        ),
      ),
    );
  }
}