// lib/router/app_router.dart
//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/incidencia_screen.dart';

// El Proveedor del Enrutador
// Al envolver GoRouter en un Provider, le damos el poder de leer otros proveedores (como el vigía de autenticación).
final routerProvider = Provider<GoRouter>((ref) {
  
  // Le decimos al enrutador: "Quédate mirando al vigía. Si el vigía grita (cambia el estado), tú te actualizas".
  // final authState = ref.watch(authStateProvider);
  final _ = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    
    // EL GUARDIÁN: Esta función se ejecuta fracciones de segundo ANTES de dibujar cualquier pantalla.
    redirect: (context, state) {
      // 1. Verificamos si hay un token válido en este instante exacto.
      final session = ref.read(supabaseProvider).auth.currentSession;
      final isLoggedIn = session != null;
      
      // 2. Verificamos a qué pantalla está intentando ir el usuario.
      final isGoingToLogin = state.uri.toString() == '/login';

      // REGLA DE HIERRO 1: Si NO está logueado y NO va al login... lo pateamos al login. (Protege las rutas privadas)
      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }

      // REGLA DE HIERRO 2: Si SÍ está logueado y trata de ir al login... lo mandamos directo adentro. (Evita que vea el login si ya entró)
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }

      // REGLA 3: Si todo es legal, devolvemos null. (Significa "Aprobado, déjalo pasar a donde iba").
      return null;
    },
    
    // El Mapa del Edificio (Las Rutas)
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/incidencias',
        builder: (context, state) => const IncidenciaScreen(),
      ),
    ],
  );
});