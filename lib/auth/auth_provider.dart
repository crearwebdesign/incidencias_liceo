// lib/auth/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Instancia Central
// Proveemos el cliente de Supabase para no tener que instanciarlo repetidas veces.
final supabaseProvider = Provider((ref) => Supabase.instance.client);

// 2. El Vigía de la Sesión (StreamProvider)
// Un Stream es un flujo continuo. Este vigía está escuchando 24/7.
// Si el usuario se loguea, cierra sesión o su token expira, esto se actualiza automáticamente.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseProvider).auth.onAuthStateChange;
});

// 3. El Inspector de Roles (FutureProvider)
// A diferencia del Stream, un Future es una consulta de un solo viaje a la base de datos.
final userRoleProvider = FutureProvider<String?>((ref) async {
  // Primero, le preguntamos a Supabase si hay una sesión activa en el celular
  final session = ref.read(supabaseProvider).auth.currentSession;

  // Si no hay sesión (usuario deslogueado), devolvemos nulo inmediatamente.
  if (session == null) return null;

  try {
    // Si hay sesión, extraemos el 'uuid' y vamos a TU tabla pública de usuarios.
    // Esto es vital porque en Supabase, 'auth.users' es privada, pero 'public.usuarios'
    // es donde tienes guardado el 'rol' (docente, director, etc).
    final response = await ref.read(supabaseProvider)
        .from('usuarios')
        .select('rol')
        .eq('id', session.user.id)
        .single(); // .single() exige que devuelva 1 sola fila exacta.

    return response['rol'] as String?;
  } catch (e) {
    // Programación defensiva: Si falla la red o el usuario no existe en la tabla, lo tratamos como nulo.
    return null;
  }
});