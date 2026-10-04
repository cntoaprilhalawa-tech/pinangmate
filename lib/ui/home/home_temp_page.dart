import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_view_model.dart';

class HomeTempPage extends StatelessWidget {
  const HomeTempPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda (sementara)')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masuk sebagai ${vm.user?.email ?? '-'}'),
            Text(vm.isAdmin ? 'Peran: admin' : 'Peran: pengguna'),
            const SizedBox(height: 16),
            FilledButton(onPressed: vm.logout, child: const Text('Keluar')),
          ],
        ),
      ),
    );
  }
}