import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda (sementara)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final k in const ['wisata', 'penginapan', 'kuliner', 'event'])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: FilledButton(
                  onPressed: () => context.push('/kategori/$k'),
                  child: Text('Lihat daftar $k'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}