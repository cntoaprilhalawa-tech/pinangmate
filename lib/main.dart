import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app/router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PinangMateApp());
}

class PinangMateApp extends StatelessWidget {
  const PinangMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PinangMate',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}