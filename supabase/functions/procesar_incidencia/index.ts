// import "jsr:@google/generative-ai@0.1.0";

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "npm:@google/generative-ai"

// 1. REGLA DE ORO DEL BACKEND: CORS (Cross-Origin Resource Sharing)
// Sin esto, tu app de Flutter rebotará al intentar conectarse al servidor.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // 2. Interceptar la petición de "pre-vuelo" (preflight) que hacen los navegadores/apps
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // 3. Extraer el texto ruidoso que envió Flutter
    const { texto_ruidoso } = await req.json()

    if (!texto_ruidoso) {
      throw new Error("Petición rechazada: Falta el campo 'texto_ruidoso'.")
    }

    // 4. Seguridad: Obtener la API Key de Google desde las variables de entorno ocultas
    const apiKey = Deno.env.get('GEMINI_API_KEY')
    if (!apiKey) {
       throw new Error("Fallo crítico: GEMINI_API_KEY no configurada en el servidor.")
    }

    // 5. Inicializar el cerebro (Gemini)
    const genAI = new GoogleGenerativeAI(apiKey)
    const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" })

    // 6. El Prompt de Ingeniería: Directo e implacable
    const prompt = `
    Analiza el siguiente reporte de incidencia escolar y extrae los datos requeridos.
    REGLAS ESTRICTAS:
    1. Devuelve ÚNICAMENTE un objeto JSON válido.
    2. CERO texto adicional, explicaciones ni bloques de código markdown (\`\`\`). Solo llaves {} y su contenido.
    3. Las claves deben ser exactamente las siguientes:
       - "estudiante_nombre" (texto)
       - "estudiante_apellido" (texto)
       - "grado" (texto)
       - "seccion" (texto)
       - "docente_reporta" (texto)
       - "materia" (texto)
       - "descripcion_falta" (texto corto resumiendo el hecho)
       - "nivel_gravedad" (debe ser estrictamente una de estas tres palabras: "leve", "moderada" o "grave")
       - "accion_sugerida" (texto)
    
    Texto a procesar: "${texto_ruidoso}"
    `;

    // 7. Ejecutar la llamada a la IA
    const result = await model.generateContent(prompt)
    let responseText = result.response.text()

    // 8. Tolerancia a fallos: Limpieza del JSON
    // A veces, aunque le prohíbas el markdown, la IA puede soltar un ```json al principio. 
    // Un verdadero ingeniero limpia el string antes de enviarlo.
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim()

    // 9. Responder a Flutter con el JSON inmaculado
    return new Response(
      responseText,
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )

  } catch (error) {
    // Si algo explota (falta de datos, error de IA), se lo decimos a Flutter ordenadamente
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
