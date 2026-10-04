import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const PlaceholderPage('Login / Registrasi')),
    GoRoute(path: '/', builder: (c, s) => const PlaceholderPage('Beranda')),
    GoRoute(path: '/kategori/:jenis', builder: (c, s) => PlaceholderPage('Daftar ${s.pathParameters['jenis']}')),
    GoRoute(path: '/item/:id', builder: (c, s) => PlaceholderPage('Detail ${s.pathParameters['id']}')),
    GoRoute(path: '/beri-nilai/:id', builder: (c, s) => const PlaceholderPage('Beri Nilai')),
    GoRoute(path: '/rencana', builder: (c, s) => const PlaceholderPage('Form Paket Rencana')),
    GoRoute(path: '/rencana/hasil', builder: (c, s) => const PlaceholderPage('Hasil Itinerary')),
    GoRoute(path: '/wishlist', builder: (c, s) => const PlaceholderPage('Wishlist')),
    GoRoute(path: '/akun', builder: (c, s) => const PlaceholderPage('Akun')),
    GoRoute(path: '/admin', builder: (c, s) => const PlaceholderPage('Admin')),
    GoRoute(path: '/admin/form', builder: (c, s) => const PlaceholderPage('Form Admin')),
  ],
);