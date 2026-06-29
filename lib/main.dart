// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'incidencias_service.dart'; // Descomenta esto cuando lo vayas a usar

void main() async {
  // Garantiza que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos la bóveda local (.env)
  await dotenv.load(fileName: ".env");

  // Inicializamos Supabase (Versión Actualizada y Limpia de Warnings)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '', // <-- ESTE ES EL CAMBIO MAESTRO
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Incidencias Liceo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text('Entorno Configurado con Éxito y Sin Advertencias')),
      ),
    );
  }
}