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



// 3. El Inspector de Perfil (Actualizado para solucionar el Bug de Caché)
final userProfileProvider = FutureProvider<({String rol, String nombre})?>((ref) async {
  
  // ¡LA SOLUCIÓN AL BUG!: Usamos ref.watch(authStateProvider) en lugar de ref.read.
  // Esto obliga a este proveedor a re-ejecutarse automáticamente cada vez que alguien hace login o logout.
  final authState = ref.watch(authStateProvider);
  final session = authState.value?.session;

  if (session == null) return null;

  try {
    // Traemos rol, nombres y apellidos desde tu tabla usuarios
    final response = await ref.read(supabaseProvider)
        .from('usuarios')
        .select('rol, nombres, apellidos')
        .eq('id', session.user.id)
        .single();

    final rol = response['rol'] as String;
    final nombreCompleto = '${response['nombres']} ${response['apellidos']}';

    // Retornamos un "Record" de Dart con ambas variables
    return (rol: rol, nombre: nombreCompleto);
  } catch (e) {
    return null;
  }
});