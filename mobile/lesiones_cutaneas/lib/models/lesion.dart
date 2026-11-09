import '../config/api_config.dart';

/// Lesión (registro de análisis) tal como la devuelve
/// GET /api/v1/predictions/usuario/{usuario_id}.
class Lesion {
  final String id;
  final String usuarioId;
  final DateTime fechaCaptura; // hora local
  final String imagenUrl;
  final String? zonaCuerpo;
  final String? clasificacion; // p. ej. "Nevus benigno"
  final String? clasificacionGeneral; // p. ej. "Benigno"
  final String? nivelRiesgo; // Bajo | Medio | Alto | Pendiente
  final double? confianza;

  /// true si un profesional confirmó el diagnóstico (Benigno/Maligno).
  /// false = "En revisión".
  final bool validacionPatologia;

  const Lesion({
    required this.id,
    required this.usuarioId,
    required this.fechaCaptura,
    required this.imagenUrl,
    this.zonaCuerpo,
    this.clasificacion,
    this.clasificacionGeneral,
    this.nivelRiesgo,
    this.confianza,
    this.validacionPatologia = false,
  });

  factory Lesion.fromJson(Map<String, dynamic> json) {
    final analisis = json['analisis_dermatologica'] as Map<String, dynamic>?;
    final resultados = analisis?['resultados'] as Map<String, dynamic>?;

    return Lesion(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String,
      fechaCaptura: _parseFechaUtc(json['fecha_captura'] as String),
      imagenUrl: ApiConfig.urlAccesible(json['imagen_movil'] as String),
      zonaCuerpo: json['zona_cuerpo'] as String?,
      clasificacion:
          resultados?['clasificacion'] as String? ??
          analisis?['clasificacion'] as String?,
      clasificacionGeneral: analisis?['clasificacion'] as String?,
      nivelRiesgo: resultados?['nivel_riesgo'] as String?,
      confianza: (resultados?['confianza'] as num?)?.toDouble(),
      validacionPatologia: analisis?['validacion_patologia'] as bool? ?? false,
    );
  }

  /// El backend guarda en UTC. Si la fecha llega sin zona horaria
  /// (registros antiguos), se interpreta como UTC y se pasa a hora local.
  static DateTime _parseFechaUtc(String valor) {
    final tieneZona = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(valor);
    return DateTime.parse(tieneZona ? valor : '${valor}Z').toLocal();
  }
}
