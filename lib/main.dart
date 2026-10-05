import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app/router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/services/nominatim_service.dart';
import 'firebase_options.dart';
import 'ui/auth/auth_view_model.dart';
import 'ui/core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepo = AuthRepository();
  final authVm = AuthViewModel(authRepo);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<ItemRepository>(create: (_) => ItemRepository()),
        Provider<NominatimService>(create: (_) => NominatimService()),
        ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
      ],
      child: PinangMateApp(router: createRouter(authVm)),
    ),
  );
}

class PinangMateApp extends StatelessWidget {
  const PinangMateApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PinangMate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}