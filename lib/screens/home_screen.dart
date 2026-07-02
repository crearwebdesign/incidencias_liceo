// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el NUEVO proveedor de perfil
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Operaciones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () async {
              await ref.read(supabaseProvider).auth.signOut();
            },
          ),
        ],
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error al cargar perfil: $error')),
        data: (perfil) {
          if (perfil == null) {
            return const Center(child: Text('Usuario sin perfil asignado. Contacte al administrador.'));
          }

          // Extraemos los datos del Record de Dart
          final rol = perfil.rol;
          final nombre = perfil.nombre;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // ESTOS SON LOS TEXTOS SOLICITADOS
              Text(
                'Bienvenido, $nombre',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Panel: ${rol.toUpperCase()}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              if (rol == 'docente') ...[
                _buildActionCard(
                  context: context,
                  title: 'Reportar Incidencia',
                  subtitle: 'Usa IA para registrar faltas de convivencia',
                  icon: Icons.gavel,
                  color: Colors.orange,
                  onTap: () {
                    debugPrint('Navegando a Incidencias...');
                  },
                ),
                _buildActionCard(
                  context: context,
                  title: 'Reservar Espacios',
                  subtitle: 'Laboratorio, Cancha o Audiovisuales',
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                  onTap: () {},
                ),
              ],

              if (rol == 'director' || rol == 'admin') ...[
                _buildActionCard(
                  context: context,
                  title: 'Panel de Incidencias',
                  subtitle: 'Métricas y auditoría de convivencia',
                  icon: Icons.analytics,
                  color: Colors.purple,
                  onTap: () {},
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}