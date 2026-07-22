// lib/screens/incidencia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/gemini_service.dart';
import '../auth/auth_provider.dart';

class IncidenciaScreen extends ConsumerStatefulWidget {
  const IncidenciaScreen({super.key});

  @override
  ConsumerState<IncidenciaScreen> createState() => _IncidenciaScreenState();
}

class _IncidenciaScreenState extends ConsumerState<IncidenciaScreen> {
  final _textoController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _textoController.dispose();
    super.dispose();
  }

Future<void> _procesarIncidencia() async {
    if (_textoController.text.trim().isEmpty) return;
    
    final textoOriginal = _textoController.text.trim();
    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Instancias de Servicios
      final geminiService = ref.read(geminiServiceProvider);
      final supabase = ref.read(supabaseProvider);
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw Exception("Sesión inválida. Vuelva a iniciar sesión.");

      // 2. Extracción con Inteligencia Artificial
      final resultado = await geminiService.analizarIncidencia(textoOriginal);

      if (resultado == null) throw Exception("La IA no pudo procesar el texto.");

      // 3. EL PUENTE LÓGICO: Buscar al estudiante en la base de datos
      // Usamos .ilike() para ignorar mayúsculas/minúsculas y .maybeSingle() para no romper la app si no existe.
      final nombreBuscado = resultado['estudiante_nombre'] ?? '';
      final apellidoBuscado = resultado['estudiante_apellido'] ?? '';

      final alumnoDB = await supabase
          .from('alumnos')
          .select('id')
          .ilike('nombres', '%$nombreBuscado%') // Busca coincidencias parciales
          .ilike('apellidos', '%$apellidoBuscado%')
          .limit(1)
          .maybeSingle();

      if (alumnoDB == null) {
        throw Exception("Estudiante no encontrado: $nombreBuscado $apellidoBuscado. Verifique el nombre.");
      }

      // 4. SANITIZACIÓN: Asegurar que la gravedad cumpla el CHECK de PostgreSQL (todo en minúsculas)
      String gravedadSanitizada = (resultado['nivel_gravedad'] ?? 'leve').toString().toLowerCase();
      // Verificación de seguridad adicional
      if (!['leve', 'moderada', 'grave'].contains(gravedadSanitizada)) {
        gravedadSanitizada = 'leve'; // Valor por defecto si la IA alucina
      }

      // 5. INSERCIÓN FINAL (La Transacción)
      await supabase.from('incidencias_ia').insert({
        'grado': resultado['grado'],
        'seccion': resultado['seccion'],
        'materia': resultado['materia'],
        'descripcion_falta': resultado['descripcion_falta'] ?? 'Descripción no generada',
        'nivel_gravedad': gravedadSanitizada,
        'accion_sugerida': resultado['accion_sugerida'],
        'texto_original_dictado': textoOriginal,
        'procesado_por_ia': true,
        'alumno_id': alumnoDB['id'], // El BigInt extraído de la BD
        'usuario_id': userId,        // El UUID del docente logueado
      });

      // 6. Éxito: Limpiar interfaz y notificar
      if (mounted) {
        _textoController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Incidencia registrada exitosamente en la Base de Datos!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        // Mostramos el error exacto (ej. Alumno no encontrado)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text('Error de Procesamiento'),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Convivencia'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            // Restringimos el ancho para que en Chrome Web mantenga proporciones legibles
            constraints: const BoxConstraints(maxWidth: 700), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.psychology, size: 64, color: Colors.blueGrey),
                const SizedBox(height: 16),
                const Text(
                  'Asistente Inteligente de Incidencias',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Redacte la situación ocurrida. La Inteligencia Artificial analizará el texto, extraerá los datos del estudiante y clasificará la gravedad de la falta.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _textoController,
                          maxLines: 7, // Campo amplio para redactar
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Ej: El alumno Carlos Mendoza interrumpió la clase y se negó a guardar silencio tras varios llamados de atención...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // EL ESPACIO RESERVADO PARA EL MICRÓFONO
                            FloatingActionButton.small(
                              heroTag: 'mic_button',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Micrófono: Instalación en la próxima fase')),
                                );
                              },
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              tooltip: 'Dictar por voz',
                              child: const Icon(Icons.mic),
                            ),
                            
                            // EL BOTÓN DE PROCESAMIENTO IA
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _procesarIncidencia,
                              icon: _isProcessing 
                                  ? const SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                    ) 
                                  : const Icon(Icons.auto_awesome),
                              label: Text(
                                _isProcessing ? 'Analizando...' : 'Procesar con IA',
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                backgroundColor: Colors.orange.shade800,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}