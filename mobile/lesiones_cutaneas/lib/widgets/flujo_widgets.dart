import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Barra superior de las pantallas del flujo de análisis:
/// botón atrás (36x36 blanco) + título "Iniciar Análisis".
class BarraFlujo extends StatelessWidget {
  const BarraFlujo({
    super.key,
    this.titulo = 'Iniciar Análisis',
    this.onAtras,
    this.oscuro = false,
  });

  final String titulo;

  /// null deshabilita el botón (p. ej. mientras se guarda).
  final VoidCallback? onAtras;

  /// Versión para fondo oscuro (pantalla de Captura).
  final bool oscuro;

  @override
  Widget build(BuildContext context) {
    final colorTexto = oscuro ? Colors.white : AppColors.textoOscuro;
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Material(
              color: oscuro
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onAtras,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.arrow_back, size: 20, color: colorTexto),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                titulo,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorTexto, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grupo de opciones tipo "pastilla" (género, municipio, zona del cuerpo).
class OpcionesChips extends StatelessWidget {
  const OpcionesChips({
    super.key,
    required this.opciones,
    required this.seleccion,
    required this.onSeleccion,
  });

  final List<String> opciones;
  final String? seleccion;
  final ValueChanged<String> onSeleccion;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in opciones)
          _Chip(texto: o, activo: o == seleccion, onTap: () => onSeleccion(o)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.texto, required this.activo, required this.onTap});

  final String texto;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: activo ? AppColors.acento : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: activo ? AppColors.acento : AppColors.borde),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // widthFactor: 1 → el chip mide lo que su texto, no todo el ancho.
          child: Center(
            widthFactor: 1,
            child: Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.white : AppColors.textoSecundario,
                fontSize: 13,
                fontWeight: activo ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón principal azul de 54 px del flujo ("Continuar al análisis", etc.).
class BotonFlujo extends StatelessWidget {
  const BotonFlujo({
    super.key,
    required this.texto,
    required this.icono,
    required this.onPressed,
    this.cargando = false,
  });

  final String texto;
  final IconData icono;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.acento,
          disabledBackgroundColor: AppColors.acento.withValues(alpha: .5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: cargando ? null : onPressed,
        icon: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icono, size: 20),
        label: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
