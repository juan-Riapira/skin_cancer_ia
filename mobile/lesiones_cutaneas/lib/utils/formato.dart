/// Formatos de texto compartidos (fechas en español, id de paciente).
class Formato {
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// "14 oct 2026"
  static String fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')} ${_meses[f.month - 1]} ${f.year}';

  /// "14 oct 2026, 09:41"
  static String fechaHora(DateTime f) =>
      '${fecha(f)}, ${f.hour.toString().padLeft(2, '0')}:'
      '${f.minute.toString().padLeft(2, '0')}';

  /// Código corto y legible del paciente a partir de su id de MongoDB:
  /// "6ac301b51c35e3068d806fb8" → "KY-6FB8".
  static String idPaciente(String usuarioId) {
    final limpio = usuarioId.trim();
    final fin = limpio.length <= 4
        ? limpio
        : limpio.substring(limpio.length - 4);
    return 'KY-${fin.toUpperCase()}';
  }

  /// 0.95 → "95%"
  static String porcentaje(double? v) =>
      v == null ? '—' : '${(v * 100).round()}%';
}
