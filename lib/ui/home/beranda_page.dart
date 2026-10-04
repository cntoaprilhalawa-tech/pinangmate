import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda (sementara)')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.push('/kategori/wisata'),
          child: const Text('Lihat daftar wisata'),
        ),
      ),
    );
  }
}