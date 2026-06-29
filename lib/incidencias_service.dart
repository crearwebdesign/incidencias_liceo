import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class IncidenciasService {
  final _supabase = Supabase.instance.client;
  
  // La URL de tu Cloud Function 

  final String cloudFunctionUrl = dotenv.env['CLOUD_FUNCTION_URL'] ?? '';
  final String secretToken = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // en el archivo .env esta las variables globales y claves ojo pila mosca

  // Esta es la función que el profesor ejecuta al dictar
  Future<void> procesarYGuardarIncidencia(String textoDictado) async {
    try {
      // 1. Mandamos el texto ruidoso a nuestra Cloud Function (Gemini)
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $secretToken',
        },
        body: jsonEncode({'texto_ruidoso': textoDictado}),
      );

      if (response.statusCode == 200) {
        // 2. Recibimos el JSON perfecto de Gemini
        Map<String, dynamic> datosEstructurados = jsonDecode(response.body);

        // 3. Guardamos DIRECTO en Supabase
        await _supabase.from('incidencias_ia').insert({
          'estudiante_nombre': datosEstructurados['estudiante_nombre'],
          'estudiante_apellido': datosEstructurados['estudiante_apellido'],
          'grado': datosEstructurados['grado'],
          'seccion': datosEstructurados['seccion'],
          'docente_reporta': datosEstructurados['docente_reporta'],
          'materia': datosEstructurados['materia'],
          'descripcion_falta': datosEstructurados['descripcion_falta'],
          'nivel_gravedad': datosEstructurados['nivel_gravedad'],
          'accion_sugerida': datosEstructurados['accion_sugerida'],
          'texto_original_dictado': textoDictado, // Guardamos el audio transcrito como evidencia
          'procesado_por_ia': true
        });

        print('¡Incidencia guardada con éxito en la base de datos!');
      } else {
        print('Error de la IA: ${response.statusCode}');
      }
    } catch (e) {
      print('Fallo crítico en el sistema: $e');
    }
  }
}