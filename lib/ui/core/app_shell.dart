import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../auth/auth_gate.dart';
import '../auth/auth_view_model.dart';
import '../plan/plan_view_model.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  void _onTap(BuildContext context, int i) {
    shell.goBranch(i, initialLocation: i == shell.currentIndex);
    final loggedIn = context.read<AuthViewModel>().loggedIn;
    // Tab 1 = Rencana, tab 2 = Wishlist: khusus yang sudah login.
    if (!loggedIn && (i == 1 || i == 2)) {
      showAjakanMasuk(context, onLater: () => shell.goBranch(0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jumlah = context.watch<PlanViewModel>().pilihan.length;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: jumlah > 0,
              label: Text('$jumlah'),
              child: const Icon(Icons.luggage_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: jumlah > 0,
              label: Text('$jumlah'),
              child: const Icon(Icons.luggage),
            ),
            label: 'Rencana',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}