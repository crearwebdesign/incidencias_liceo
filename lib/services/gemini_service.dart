// lib/services/gemini_service.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

final geminiServiceProvider = Provider((ref) => GeminiService());

class GeminiService {
  Future<Map<String, dynamic>?> analizarIncidencia(String textoRuidoso) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Fallo crítico: GEMINI_API_KEY no configurada en el archivo .env');
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    // El Prompt de Ingeniería: Rescatamos tu estructura de Deno, 
    // adaptada a los campos exactos de tu tabla SQL.
    final prompt = '''
    Analiza el siguiente reporte de incidencia escolar dictado por un docente.
    REGLAS ESTRICTAS:
    1. Devuelve ÚNICAMENTE un objeto JSON válido.
    2. CERO texto adicional, explicaciones ni bloques de código markdown.
    3. Las claves deben ser exactamente las siguientes y si un dato no se menciona, devuelve null:
       - "estudiante_nombre" (texto, solo nombres)
       - "estudiante_apellido" (texto, solo apellidos)
       - "grado" (texto)
       - "seccion" (texto)
       - "materia" (texto)
       - "descripcion_falta" (texto corto resumiendo el hecho)
       - "nivel_gravedad" (debe ser estrictamente: "leve", "moderada" o "grave")
       - "accion_sugerida" (texto)
    
    Texto a procesar: "$textoRuidoso"
    ''';

    final content = [Content.text(prompt)];
    final result = await model.generateContent(content);

    if (result.text != null) {
      // Limpieza de seguridad por si la IA ignora la regla del markdown (como en tu Deno)
      String cleanText = result.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanText);
    }
    return null;
  }
}