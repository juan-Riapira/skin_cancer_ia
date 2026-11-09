import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/cuerpo_interactivo.dart';
import '../widgets/flujo_widgets.dart';
import '../widgets/pasos_analisis.dart';
import 'captura_imagen_screen.dart';

/// Paso 2 del flujo de análisis: zona del cuerpo donde está la lesión
/// (diseño Figma "Ubicación de la Lesión").
///
/// La zona se envía al backend junto con la foto en el paso 3 (Captura),
/// como campo `zona_cuerpo` de POST /api/v1/predictions.
class UbicacionLesionScreen extends StatefulWidget {
  const UbicacionLesionScreen({super.key, required this.usuarioId});

  final String usuarioId;

  @override
  State<UbicacionLesionScreen> createState() => _UbicacionLesionScreenState();
}

class _UbicacionLesionScreenState extends State<UbicacionLesionScreen> {
  String? _zona;
  bool _posterior = true; // el diseño abre en vista posterior

  void _seleccionar(String zona) {
    setState(() {
      _zona = zona;
      // Si se elige con los botones una zona que no está a la vista, girar.
      final vista = ZonaCuerpo.enVistaPosterior(zona);
      if (vista != null) _posterior = vista;
    });
  }

  void _girar() => setState(() => _posterior = !_posterior);

  void _continuar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturaImagenScreen(
          usuarioId: widget.usuarioId,
          zonaCuerpo: _zona!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoFormulario,
      body: SafeArea(
        child: Column(
          children: [
            BarraFlujo(onAtras: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PasosAnalisis(pasoActual: 1),
                    const SizedBox(height: 14),
                    const Text(
                      'Selecciona la zona de la lesión',
                      style: TextStyle(
                        color: AppColors.textoOscuro,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Toca una zona para ubicar tu análisis.',
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _tarjetaCuerpo(),
                    const SizedBox(height: 18),
                    OpcionesChips(
                      opciones: ZonaCuerpo.todas,
                      seleccion: _zona,
                      onSeleccion: _seleccionar,
                    ),
                    const SizedBox(height: 24),
                    BotonFlujo(
                      texto: 'Continuar a Captura',
                      icono: Icons.photo_camera_outlined,
                      onPressed: _zona == null ? null : _continuar,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaCuerpo() {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Silueta: arrastrar horizontalmente gira el cuerpo.
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0).abs() > 100) _girar();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 44, 16, 50),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: _giro,
                  child: CuerpoInteractivo(
                    key: ValueKey(_posterior),
                    posterior: _posterior,
                    seleccion: _zona,
                    onZona: _seleccionar,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: _Etiqueta(
              texto: _posterior ? 'VISTA POSTERIOR' : 'VISTA FRONTAL',
            ),
          ),
          if (_zona != null)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.acento,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, size: 12, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      _zona!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Material(
                color: AppColors.fondoFormulario,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _girar, // también se puede tocar para girar
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.threesixty,
                          size: 17,
                          color: AppColors.textoSecundario,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Arrastra para girar',
                          style: TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Transición de "giro" en el eje Y al cambiar de vista.
  static Widget _giro(Widget child, Animation<double> anim) {
    return AnimatedBuilder(
      animation: anim,
      child: child,
      builder: (_, c) => Opacity(
        opacity: anim.value < .5 ? 0 : 1,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY((1 - anim.value) * math.pi / 2),
          child: c,
        ),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.fondoFormulario,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.textoSecundario,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
