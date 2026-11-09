import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/lesion.dart';
import '../models/usuario.dart';
import '../services/lesion_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_colors.dart';
import '../utils/formato.dart';
import '../widgets/flujo_widgets.dart';
import '../widgets/pasos_analisis.dart';
import 'resultado_analisis_screen.dart';

/// Paso 4 del flujo: "Analizando..." (diseño Figma).
///
/// Envía la foto al backend (se guarda en MinIO + MongoDB) mientras muestra
/// el avance por etapas. SIMULACIÓN: como aún no hay modelo de IA, las etapas
/// avanzan con un temporizador (~4 s) y el resultado es el análisis por
/// defecto que devuelve el backend. La pantalla solo avanza cuando la
/// animación terminó Y el backend respondió.
class AnalizandoScreen extends StatefulWidget {
  const AnalizandoScreen({
    super.key,
    required this.usuarioId,
    required this.zonaCuerpo,
    required this.imagen,
    required this.nombreArchivo,
  });

  final String usuarioId;
  final String zonaCuerpo;
  final Uint8List imagen;
  final String nombreArchivo;

  @override
  State<AnalizandoScreen> createState() => _AnalizandoScreenState();
}

class _AnalizandoScreenState extends State<AnalizandoScreen>
    with SingleTickerProviderStateMixin {
  static const _etapas = [
    'Imagen preparada',
    'Características evaluadas',
    'Generando orientación',
  ];

  late final AnimationController _avance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  final _fecha = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _procesar();
  }

  @override
  void dispose() {
    _avance.dispose();
    super.dispose();
  }

  Future<void> _procesar() async {
    setState(() => _error = null);
    _avance.value = 0;
    // La animación se detiene en 90 % hasta que responda el backend.
    final simulacion = _avance.animateTo(0.9);

    try {
      final (lesion, usuario) = await (
        LesionService().crearLesion(
          usuarioId: widget.usuarioId,
          zonaCuerpo: widget.zonaCuerpo,
          imagen: widget.imagen,
          nombreArchivo: widget.nombreArchivo,
        ),
        // El nombre solo se usa para mostrarlo; si falla, no es crítico.
        UsuarioService()
            .obtenerUsuario(widget.usuarioId)
            .then<Usuario?>((u) => u)
            .catchError((_) => null),
      ).wait;

      await simulacion;
      if (!mounted) return;
      await _avance.animateTo(1, duration: const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      _irAResultado(lesion, usuario);
    } catch (e) {
      if (!mounted) return;
      _avance.stop();
      // `.wait` envuelve el error; se extrae el de la subida de la foto.
      final causa = e is ParallelWaitError
          ? (e.errors as (AsyncError?, AsyncError?)).$1?.error ?? e
          : e;
      final mensaje = causa.toString();
      setState(() => _error = mensaje.replaceFirst('Exception: ', ''));
    }
  }

  void _irAResultado(Lesion lesion, Usuario? usuario) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => ResultadoAnalisisScreen(
          lesion: lesion,
          usuario: usuario,
          imagen: widget.imagen,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  bool get _procesando => _error == null;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // No se puede salir mientras se envía la imagen.
      canPop: !_procesando,
      child: Scaffold(
        backgroundColor: AppColors.fondoFormulario,
        body: SafeArea(
          child: Column(
            children: [
              BarraFlujo(
                titulo: 'Analizando...',
                onAtras: _procesando ? null : () => Navigator.pop(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    children: [
                      const PasosAnalisis(pasoActual: 3),
                      const SizedBox(height: 18),
                      _tarjeta(),
                      const SizedBox(height: 18),
                      if (_error == null) _listaEtapas() else _panelError(),
                      const SizedBox(height: 24),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: AppColors.textoSecundario,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Privacidad y cuidado en cada paso.',
                              style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjeta() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            widget.imagen,
            height: 192,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 192,
              color: AppColors.primarioClaro,
              child: const Icon(
                Icons.image_outlined,
                color: AppColors.primario,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        AnimatedBuilder(
          animation: _avance,
          builder: (_, _) =>
              _Anillo(valor: _avance.value, error: _error != null),
        ),
        const SizedBox(height: 22),
        Text(
          _error == null ? 'Analizando...' : 'No se pudo completar',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textoOscuro,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _error ??
              'Procesando imagen con IA y guardando de forma segura '
                  'en KycabItA...',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borde)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.zonaCuerpo} · ${Formato.fecha(_fecha)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                Formato.idPaciente(widget.usuarioId),
                style: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _listaEtapas() => AnimatedBuilder(
    animation: _avance,
    builder: (_, _) {
      final v = _avance.value;
      final actual = v >= 1
          ? _etapas.length
          : v < .3
          ? 0
          : v < .65
          ? 1
          : 2;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var i = 0; i < _etapas.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              _Etapa(
                texto: _etapas[i],
                estado: i < actual
                    ? _EstadoEtapa.lista
                    : i == actual
                    ? _EstadoEtapa.enCurso
                    : _EstadoEtapa.pendiente,
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _panelError() => Column(
    children: [
      BotonFlujo(
        texto: 'Reintentar',
        icono: Icons.refresh,
        onPressed: _procesar,
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.photo_camera_outlined, size: 18),
        label: const Text('Volver a la cámara'),
      ),
    ],
  );
}

/// Anillo de progreso de 88 px con el porcentaje en el centro.
class _Anillo extends StatelessWidget {
  const _Anillo({required this.valor, required this.error});

  final double valor;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.riesgoAlto : AppColors.acento;
    return SizedBox(
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _AnilloPainter(valor: valor, color: color),
        child: Center(
          child: error
              ? Icon(Icons.close, color: color, size: 32)
              : Text(
                  '${(valor * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _AnilloPainter extends CustomPainter {
  _AnilloPainter({required this.valor, required this.color});

  final double valor;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const grosor = 6.0;
    final rect = (Offset.zero & size).deflate(grosor / 2);
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xFFEAF3FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * valor,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = grosor,
    );
  }

  @override
  bool shouldRepaint(_AnilloPainter old) =>
      old.valor != valor || old.color != color;
}

enum _EstadoEtapa { lista, enCurso, pendiente }

class _Etapa extends StatelessWidget {
  const _Etapa({required this.texto, required this.estado});

  final String texto;
  final _EstadoEtapa estado;

  @override
  Widget build(BuildContext context) {
    final icono = switch (estado) {
      _EstadoEtapa.lista => const Icon(
        Icons.check_circle,
        size: 18,
        color: AppColors.riesgoBajo,
      ),
      _EstadoEtapa.enCurso => const SizedBox(
        width: 18,
        height: 18,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.acento,
          ),
        ),
      ),
      _EstadoEtapa.pendiente => const Icon(
        Icons.radio_button_unchecked,
        size: 18,
        color: AppColors.pasoInactivo,
      ),
    };
    final enCurso = estado == _EstadoEtapa.enCurso;
    return Row(
      children: [
        icono,
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(
              color: enCurso ? AppColors.acento : AppColors.textoSecundario,
              fontSize: 13,
              fontWeight: enCurso ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
