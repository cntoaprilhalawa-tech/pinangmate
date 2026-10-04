import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_view_model.dart';

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: Center(
        child: vm.loggedIn
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle, size: 64),
                  const SizedBox(height: 8),
                  Text(vm.user?.email ?? '-'),
                  Text(vm.isAdmin ? 'Peran: admin' : 'Peran: pengguna'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: vm.logout,
                    child: const Text('Keluar'),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Kamu belum masuk'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Masuk / Daftar'),
                  ),
                ],
              ),
      ),
    );
  }
}