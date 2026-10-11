import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../ui/wishlist/wishlist_page.dart';
import '../ui/admin/admin_form_page.dart';
import '../ui/admin/admin_page.dart';
import '../ui/admin/location_picker_page.dart';
import '../ui/auth/akun_page.dart';
import '../ui/auth/auth_gate.dart';
import '../ui/auth/auth_view_model.dart';
import '../ui/auth/login_page.dart';
import '../ui/category/category_list_page.dart';
import '../ui/core/app_shell.dart';
import '../ui/detail/item_detail_page.dart';
import '../ui/home/beranda_page.dart';
import '../ui/plan/plan_form_page.dart';
import '../ui/plan/plan_result_page.dart';
import '../ui/plan/saved_plans_page.dart';
import '../ui/search/search_page.dart';

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
    refreshListenable: auth.routerRefresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!auth.ready) return loc == '/splash' ? null : '/splash';
      if (loc == '/splash') return '/';
      if (auth.loggedIn && loc == '/login') return '/';
      if (loc.startsWith('/admin') && !auth.isAdmin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (c, s) => const BerandaPage(),
              routes: [
                GoRoute(
                  path: 'kategori/:jenis',
                  builder: (c, s) => CategoryListPage(
                    kategori: kategoriFromRoute(s.pathParameters['jenis']),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
                                  GoRoute(
              path: '/rencana',
              builder: (c, s) => const AuthGate(child: PlanFormPage()),
              routes: [
                GoRoute(
                  path: 'hasil',
                  builder: (c, s) => const AuthGate(child: PlanResultPage()),
                ),
                GoRoute(
                  path: 'tersimpan',
                  builder: (c, s) => const AuthGate(child: SavedPlansPage()),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (c, s) => AuthGate(
                        child: SavedPlanPage(id: s.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/wishlist',
              builder: (c, s) =>
                 const AuthGate(child: WishlistPage())
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/akun', builder: (c, s) => const AkunPage()),
          ]),
        ],
      ),
      GoRoute(
        path: '/item/:id',
        builder: (c, s) => ItemDetailPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/beri-nilai/:id',
        builder: (c, s) => const PlaceholderPage('Beri Nilai'),
      ),
            GoRoute(path: '/cari', builder: (c, s) => const SearchPage()),
      GoRoute(path: '/admin', builder: (c, s) => const AdminPage()),
      GoRoute(
        path: '/admin/form',
        builder: (c, s) => AdminFormPage(
          id: s.uri.queryParameters['id'],
          kategori: kategoriFromRoute(s.uri.queryParameters['kategori']),
        ),
      ),
      GoRoute(
        path: '/admin/lokasi',
        builder: (c, s) => LocationPickerPage(initial: s.extra as LatLng?),
      ),
    ],
  );
}