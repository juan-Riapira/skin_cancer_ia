import 'package:flutter/material.dart';

/// Presentación del resultado según el nivel de riesgo que devuelve el
/// backend (`analisis_dermatologica.resultados.nivel_riesgo`).
///
/// SIMULACIÓN: mientras no exista el modelo de IA, los textos de
/// "Hallazgos" y "¿Qué hacer ahora?" son orientativos y fijos por nivel.
class Orientacion {
  const Orientacion({
    required this.nivel,
    required this.fondo,
    required this.borde,
    required this.acento,
    required this.titulo,
    required this.icono,
    required this.hallazgos,
    required this.recomendacion,
  });

  final String nivel;
  final Color fondo;
  final Color borde;
  final Color acento; // etiqueta y nota
  final Color titulo; // "Riesgo Bajo", "95%"
  final IconData icono;
  final String hallazgos;
  final String recomendacion;

  static Orientacion de(String? nivelRiesgo) {
    switch (nivelRiesgo?.toLowerCase()) {
      case 'bajo':
        return const Orientacion(
          nivel: 'Bajo',
          fondo: Color(0xFFECFDF5),
          borde: Color(0xFFD7F8D6),
          acento: Color(0xFF047857),
          titulo: Color(0xCE006246),
          icono: Icons.verified_outlined,
          hallazgos:
              'La IA sugiere una apariencia simétrica y pigmentación uniforme. '
              'Estos hallazgos requieren valoración clínica.',
          recomendacion:
              'Monitorear cambios de forma o color y consultar al dermatólogo.',
        );
      case 'medio':
        return const Orientacion(
          nivel: 'Medio',
          fondo: Color(0xFFFFFBEB),
          borde: Color(0xFFFDE68A),
          acento: Color(0xFFB45309),
          titulo: Color(0xFF92400E),
          icono: Icons.info_outline,
          hallazgos:
              'La IA detecta algunas irregularidades en el borde o el color. '
              'Estos hallazgos requieren valoración clínica.',
          recomendacion:
              'Agendar una consulta con el dermatólogo en las próximas semanas.',
        );
      case 'alto':
        return const Orientacion(
          nivel: 'Alto',
          fondo: Color(0xFFFEF2F2),
          borde: Color(0xFFFECACA),
          acento: Color(0xFFB91C1C),
          titulo: Color(0xFF991B1B),
          icono: Icons.warning_amber_rounded,
          hallazgos:
              'La IA detecta asimetría y variaciones de color que conviene '
              'revisar pronto. Estos hallazgos requieren valoración clínica.',
          recomendacion:
              'Consultar al dermatólogo lo antes posible para una valoración.',
        );
      default:
        return const Orientacion(
          nivel: 'Pendiente',
          fondo: Color(0xFFF1F5F9),
          borde: Color(0xFFE2E8F0),
          acento: Color(0xFF475569),
          titulo: Color(0xFF334155),
          icono: Icons.hourglass_empty,
          hallazgos:
              'El análisis de esta imagen aún está pendiente de revisión.',
          recomendacion:
              'Ante cualquier cambio en la lesión, consultar al dermatólogo.',
        );
    }
  }
}
