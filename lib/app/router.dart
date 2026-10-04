import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/auth/auth_view_model.dart';
import '../ui/auth/login_page.dart';
import '../ui/home/home_temp_page.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}

GoRouter createRouter(AuthViewModel auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Tunggu status login pertama diketahui.
      if (!auth.ready) return loc == '/splash' ? null : '/splash';
      if (loc == '/splash') return auth.loggedIn ? '/' : '/login';
      if (auth.loggedIn && loc == '/login') return '/';
      // Sementara: beranda hanya untuk yang login. Nanti tamu boleh masuk.
      if (!auth.loggedIn && loc == '/') return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/', builder: (c, s) => const HomeTempPage()),
      GoRoute(
        path: '/kategori/:jenis',
        builder: (c, s) => PlaceholderPage('Daftar ${s.pathParameters['jenis']}'),
      ),
      GoRoute(
        path: '/item/:id',
        builder: (c, s) => PlaceholderPage('Detail ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/beri-nilai/:id',
        builder: (c, s) => const PlaceholderPage('Beri Nilai'),
      ),
      GoRoute(
        path: '/rencana',
        builder: (c, s) => const PlaceholderPage('Form Paket Rencana'),
      ),
      GoRoute(
        path: '/rencana/hasil',
        builder: (c, s) => const PlaceholderPage('Hasil Itinerary'),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (c, s) => const PlaceholderPage('Wishlist'),
      ),
      GoRoute(path: '/akun', builder: (c, s) => const PlaceholderPage('Akun')),
      GoRoute(path: '/admin', builder: (c, s) => const PlaceholderPage('Admin')),
      GoRoute(
        path: '/admin/form',
        builder: (c, s) => const PlaceholderPage('Form Admin'),
      ),
    ],
  );
}