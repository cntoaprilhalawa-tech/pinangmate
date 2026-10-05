import 'package:flutter/material.dart';

import '../../data/models/item.dart';
import '../core/launchers.dart';

class ContactBar extends StatelessWidget {
  const ContactBar({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final kontak = item.kontak?.trim();
    final ada = kontak != null && kontak.isNotEmpty;
    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: ada ? () => _pilih(context, kontak) : null,
              icon: const Icon(Icons.call_outlined),
              label: Text(ada ? 'Hubungi Penyedia' : 'Kontak belum tersedia'),
            ),
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