import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Colores del indicador según el fondo (claro u oscuro).
class _Tema {
  const _Tema({
    required this.activo,
    required this.puntoInactivo,
    required this.textoInactivo,
    required this.barraInactiva,
    required this.fondoEtiqueta,
    required this.separador,
    required this.check,
  });

  final Color activo;
  final Color puntoInactivo;
  final Color textoInactivo;
  final Color barraInactiva;
  final Color fondoEtiqueta;
  final Color separador;
  final Color check;

  static const claro = _Tema(
    activo: AppColors.acento,
    puntoInactivo: AppColors.pasoInactivo,
    textoInactivo: AppColors.textoSecundario,
    barraInactiva: AppColors.borde,
    fondoEtiqueta: AppColors.azulSuave,
    separador: AppColors.textoSecundario,
    check: Colors.white,
  );

  // Pantalla de Captura (fondo oscuro)
  static const oscuro = _Tema(
    activo: AppColors.oscuroActivo,
    puntoInactivo: Color(0xFF4A5B70),
    textoInactivo: AppColors.oscuroTextoSecundario,
    barraInactiva: Color(0xFF3A4C61),
    fondoEtiqueta: AppColors.oscuroTarjeta,
    separador: AppColors.oscuroTextoSecundario,
    check: AppColors.oscuroFondo,
  );
}

/// Indicador de progreso del flujo de análisis (diseño Figma).
/// [pasoActual] empieza en 0: 0 = Registro, 1 = Ubicación, 2 = Captura, 3 = Análisis.
class PasosAnalisis extends StatelessWidget {
  const PasosAnalisis({
    super.key,
    required this.pasoActual,
    this.oscuro = false,
  });

  final int pasoActual;
  final bool oscuro;

  static const pasos = ['Registro', 'Ubicación', 'Captura', 'Análisis'];

  @override
  Widget build(BuildContext context) {
    final tema = oscuro ? _Tema.oscuro : _Tema.claro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < pasos.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _Paso(
                  nombre: pasos[i],
                  activo: i <= pasoActual,
                  tema: tema,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: tema.fondoEtiqueta,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'PASO ${pasoActual + 1} DE ${pasos.length}',
                style: TextStyle(
                  color: tema.activo,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('·', style: TextStyle(color: tema.separador, fontSize: 10)),
            const SizedBox(width: 6),
            Text(
              pasos[pasoActual].toUpperCase(),
              style: TextStyle(
                color: tema.activo,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.nombre, required this.activo, required this.tema});

  final String nombre;
  final bool activo;
  final _Tema tema;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: activo ? tema.activo : tema.puntoInactivo,
                shape: BoxShape.circle,
              ),
              child: activo
                  ? Icon(Icons.check, size: 10, color: tema.check)
                  : null,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: activo ? tema.activo : tema.textoInactivo,
                  fontSize: 9,
                  fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: activo ? tema.activo : tema.barraInactiva,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
