// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importamos Riverpod
import 'router/app_router.dart'; // Importamos tu nuevo Guardián

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Envolvemos toda la app en un ProviderScope para que Riverpod funcione
  runApp(const ProviderScope(child: MyApp()));
}

// Convertimos MyApp a ConsumerWidget para que pueda leer los Providers
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Leemos tu enrutador
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'App Utilidades Liceo',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Le entregamos las llaves del carro al Guardián
      routerConfig: router,
    );
  }
}