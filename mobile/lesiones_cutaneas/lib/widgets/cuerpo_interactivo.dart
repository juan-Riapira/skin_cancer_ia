import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Zonas del cuerpo. El texto es el que se guarda en el backend
/// (campo `zona_cuerpo` de la lesión).
class ZonaCuerpo {
  static const brazo = 'Brazo';
  static const espalda = 'Espalda';
  static const rostro = 'Rostro';
  static const pierna = 'Pierna';
  static const torso = 'Torso';

  static const todas = [brazo, espalda, rostro, pierna, torso];

  /// Vista en la que se ve cada zona (true = posterior).
  static bool? enVistaPosterior(String zona) => switch (zona) {
    espalda => true,
    rostro || torso => false,
    _ => null, // brazos y piernas se ven en ambas vistas
  };
}

/// Silueta del cuerpo dibujada por código, con zonas tocables.
/// Coordenadas en una grilla de 100 x 130 que se escala al espacio disponible.
class CuerpoInteractivo extends StatelessWidget {
  const CuerpoInteractivo({
    super.key,
    required this.posterior,
    required this.seleccion,
    required this.onZona,
  });

  final bool posterior;
  final String? seleccion;
  final ValueChanged<String> onZona;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final zona = _Silueta(posterior).zonaEn(d.localPosition, size);
            if (zona != null) onZona(zona);
          },
          child: CustomPaint(
            size: size,
            painter: _CuerpoPainter(posterior: posterior, seleccion: seleccion),
          ),
        );
      },
    );
  }
}

/// Geometría de la silueta (compartida por el dibujo y el toque).
class _Silueta {
  _Silueta(this.posterior);

  final bool posterior;

  static const _ancho = 100.0;
  static const _alto = 130.0;

  /// Cada parte: zona (o null si no es seleccionable) + forma.
  List<(String?, RRect)> get partes => [
    // Cabeza: en vista posterior no es "Rostro".
    (
      posterior ? null : ZonaCuerpo.rostro,
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(41, 2, 18, 21),
        const Radius.circular(9),
      ),
    ),
    (null, _r(46, 21, 8, 6, 2)), // cuello
    (posterior ? ZonaCuerpo.espalda : ZonaCuerpo.torso, _r(32, 26, 36, 46, 9)),
    (ZonaCuerpo.brazo, _r(20, 27, 10, 46, 5)),
    (ZonaCuerpo.brazo, _r(70, 27, 10, 46, 5)),
    (ZonaCuerpo.pierna, _r(34, 73, 14, 54, 6)),
    (ZonaCuerpo.pierna, _r(52, 73, 14, 54, 6)),
  ];

  static RRect _r(double l, double t, double w, double h, double r) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));

  /// Escala y desplazamiento para centrar la grilla en [size].
  (double, Offset) transformacion(Size size) {
    final escala = (size.width / _ancho).clamp(0.0, size.height / _alto);
    final offset = Offset(
      (size.width - _ancho * escala) / 2,
      (size.height - _alto * escala) / 2,
    );
    return (escala, offset);
  }

  String? zonaEn(Offset punto, Size size) {
    final (escala, offset) = transformacion(size);
    final p = (punto - offset) / escala;
    for (final (zona, forma) in partes) {
      // margen de 3 unidades para que los brazos sean fáciles de tocar
      if (zona != null && forma.outerRect.inflate(3).contains(p)) return zona;
    }
    return null;
  }
}

class _CuerpoPainter extends CustomPainter {
  _CuerpoPainter({required this.posterior, required this.seleccion});

  final bool posterior;
  final String? seleccion;

  @override
  void paint(Canvas canvas, Size size) {
    final silueta = _Silueta(posterior);
    final (escala, offset) = silueta.transformacion(size);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(escala);

    final relleno = Paint()..color = AppColors.fondoFormulario;
    final rellenoActivo = Paint()
      ..color = AppColors.acento.withValues(alpha: .85);
    final borde = Paint()
      ..color = AppColors.pasoInactivo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / escala * 2;
    final bordeActivo = Paint()
      ..color = AppColors.acento
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 / escala * 2;

    for (final (zona, forma) in silueta.partes) {
      final activo = zona != null && zona == seleccion;
      canvas.drawRRect(forma, activo ? rellenoActivo : relleno);
      canvas.drawRRect(forma, activo ? bordeActivo : borde);
    }

    // Detalles para distinguir la vista frontal de la posterior.
    final detalle = Paint()
      ..color = AppColors.pasoInactivo
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    if (posterior) {
      // columna vertebral
      final activo = seleccion == ZonaCuerpo.espalda;
      detalle.color = activo ? Colors.white70 : AppColors.pasoInactivo;
      canvas.drawLine(const Offset(50, 30), const Offset(50, 68), detalle);
    } else {
      // ojos y boca
      final activo = seleccion == ZonaCuerpo.rostro;
      final cara = Paint()
        ..color = activo ? Colors.white : AppColors.textoSecundario;
      canvas.drawCircle(const Offset(46.5, 11), 1, cara);
      canvas.drawCircle(const Offset(53.5, 11), 1, cara);
      detalle.color = cara.color;
      canvas.drawArc(
        const Rect.fromLTWH(47, 13, 6, 4),
        0.3,
        2.5,
        false,
        detalle,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CuerpoPainter old) =>
      old.posterior != posterior || old.seleccion != seleccion;
}
