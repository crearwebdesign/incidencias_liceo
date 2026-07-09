// lib/screens/incidencia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // Esta función es el "esqueleto" que luego conectaremos con Gemini
  void _procesarIncidencia() {
    if (_textoController.text.trim().isEmpty) return;
    
    // Cerramos el teclado virtual si se está usando en móvil
    FocusScope.of(context).unfocus();

    setState(() {
      _isProcessing = true;
    });

    // Simulamos una espera de 2 segundos. 
    // En el próximo paso, reemplazaremos esto con la llamada a la Edge Function.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        // Feedback visual temporal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interfaz lista. Esperando integración con la IA.')),
        );
      }
    });
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