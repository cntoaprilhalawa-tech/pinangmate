import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'data/repositories/wishlist_repository.dart';
import 'ui/wishlist/wishlist_view_model.dart';
import 'data/repositories/rating_repository.dart';
import 'app/router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/services/nominatim_service.dart';
import 'firebase_options.dart';
import 'ui/auth/auth_view_model.dart';
import 'ui/core/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/services/location_service.dart';
import 'data/repositories/plan_repository.dart';
import 'ui/plan/plan_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final authRepo = AuthRepository();
  final authVm = AuthViewModel(authRepo);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),

        // AuthViewModel HARUS di atas PlanViewModel supaya bisa dibaca.
        ChangeNotifierProvider<AuthViewModel>.value(value: authVm),

        Provider<ItemRepository>(create: (_) => ItemRepository()),
        Provider<RatingRepository>(create: (_) => RatingRepository()),
        Provider<PlanRepository>(create: (_) => PlanRepository()),
        ChangeNotifierProvider<PlanViewModel>(
          create: (c) => PlanViewModel(
            c.read<PlanRepository>(),
            c.read<AuthViewModel>(),
          ),
        ),
        Provider<WishlistRepository>(create: (_) => WishlistRepository()),
        Provider<LocationService>(create: (_) => LocationService()),
        ChangeNotifierProvider<WishlistViewModel>(
          create: (c) => WishlistViewModel(
            c.read<WishlistRepository>(),
            c.read<ItemRepository>(),
            authVm,
          ),
        ),
        Provider<NominatimService>(create: (_) => NominatimService()),
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