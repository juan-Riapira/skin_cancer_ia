import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/lesion.dart';
import '../models/usuario.dart';
import '../services/lesion_service.dart';
import '../services/usuario_service.dart';
import '../utils/app_colors.dart';
import 'historial_view.dart';
import 'registro_usuario_screen.dart';
import 'resultado_analisis_screen.dart';

/// Pantalla de Inicio (diseño Figma "Inicio").
/// Carga el usuario y su historial de lesiones desde el backend.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.usuarioId = ApiConfig.usuarioId});

  final String usuarioId;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _usuarioService = UsuarioService();
  final _lesionService = LesionService();

  int _tab = 0;
  late String _usuarioId = widget.usuarioId;
  late Future<(Usuario, List<Lesion>)> _datos;

  @override
  void initState() {
    super.initState();
    _datos = _cargar();
    // Recargar cuando se guarda una lesión nueva en el flujo de análisis.
    LesionService.cambios.addListener(_recargar);
  }

  @override
  void dispose() {
    LesionService.cambios.removeListener(_recargar);
    super.dispose();
  }

  Future<(Usuario, List<Lesion>)> _cargar() async {
    final resultados = await Future.wait([
      _usuarioService.obtenerUsuario(_usuarioId),
      _lesionService.listarPorUsuario(_usuarioId),
    ]);
    return (resultados[0] as Usuario, resultados[1] as List<Lesion>);
  }

  Future<void> _recargar() async {
    final futuro = _cargar();
    setState(() {
      _datos = futuro;
    });
    try {
      await futuro;
    } catch (_) {
      // El error se muestra en pantalla vía FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: FutureBuilder<(Usuario, List<Lesion>)>(
        future: _datos,
        builder: (context, snap) {
          final usuario = snap.data?.$1;
          final lesiones = snap.data?.$2;
          final cargando = snap.connectionState == ConnectionState.waiting;

          // Pestañas: 0 Inicio · 1 Historial · 2 Herramientas.
          // IndexedStack conserva la búsqueda/filtros del Historial.
          return IndexedStack(
            index: _tab,
            children: [
              _inicio(snap, usuario, lesiones),
              HistorialView(
                lesiones: lesiones,
                cargando: cargando,
                error: snap.hasError ? _limpiarError(snap.error) : null,
                onRecargar: _recargar,
                onAbrir: (l) => _abrirDetalle(l, usuario),
              ),
              const _Proximamente(),
            ],
          );
        },
      ),
      bottomNavigationBar: _BarraNavegacion(
        indice: _tab,
        onSeleccion: (i) => setState(() => _tab = i),
      ),
    );
  }

  Widget _inicio(
    AsyncSnapshot<(Usuario, List<Lesion>)> snap,
    Usuario? usuario,
    List<Lesion>? lesiones,
  ) {
    return RefreshIndicator(
      onRefresh: _recargar,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Encabezado(nombre: usuario?.primerNombre),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TarjetaAnalisis(onIniciar: _iniciarAnalisis),
                const SizedBox(height: 20),
                _tituloRegistros(lesiones?.length),
                const SizedBox(height: 10),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snap.hasError)
                  _MensajeEstado(
                    icono: Icons.cloud_off,
                    texto:
                        'No se pudieron cargar tus registros.\n${_limpiarError(snap.error)}',
                    accion: 'Reintentar',
                    onAccion: _recargar,
                  )
                else if (lesiones!.isEmpty)
                  const _MensajeEstado(
                    icono: Icons.photo_camera_outlined,
                    texto:
                        'Aún no tienes análisis.\nToca "Iniciar Análisis" para hacer el primero.',
                  )
                else
                  for (final l in lesiones) ...[
                    _TarjetaRegistro(
                      lesion: l,
                      onTap: () => _abrirDetalle(l, usuario),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloRegistros(int? total) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Mis Registros',
        style: TextStyle(
          color: AppColors.textoOscuro,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      if (total != null)
        Text(
          '$total análisis',
          style: const TextStyle(
            color: AppColors.textoSecundario,
            fontSize: 12,
          ),
        ),
    ],
  );

  String _limpiarError(Object? e) =>
      e.toString().replaceFirst('Exception: ', '');

  /// Abre el flujo de análisis (Registro → Ubicación → …). Cuando el registro
  /// se guarda, Inicio pasa a mostrar los datos de ese usuario.
  Future<void> _iniciarAnalisis() async {
    final nuevoId = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RegistroUsuarioScreen()),
    );
    if (nuevoId == null || !mounted) return;

    _usuarioId = nuevoId;
    _recargar();
  }

  void _abrirDetalle(Lesion l, Usuario? usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoAnalisisScreen(
          lesion: l,
          usuario: usuario,
          desdeHistorial: true,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes
// ---------------------------------------------------------------------------

class _Encabezado extends StatelessWidget {
  const _Encabezado({this.nombre});

  final String? nombre;

  @override
  Widget build(BuildContext context) {
    final saludo = (nombre == null || nombre!.isEmpty)
        ? 'Bienvenido'
        : 'Bienvenido, $nombre';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.paddingOf(context).top + 16,
        24,
        24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primario,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                // TODO: reemplazar por el logo exportado de Figma
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.acento,
                  borderRadius: BorderRadius.circular(7.84),
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KycabItA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                tooltip: 'Notificaciones',
                icon: const Icon(
                  Icons.notifications_none,
                  size: 21,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            saludo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Un nuevo día para cuidar de ti y de tu piel.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaAnalisis extends StatelessWidget {
  const _TarjetaAnalisis({required this.onIniciar});

  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primarioClaro,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              size: 34,
              color: AppColors.primario,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Revisar un lunar o mancha',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoOscuro,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Toma una foto a la mancha de tu piel y recibe una orientación '
            'rápida con Inteligencia Artificial.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primario,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onIniciar,
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: const Text(
                'Iniciar Análisis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaRegistro extends StatelessWidget {
  const _TarjetaRegistro({required this.lesion, required this.onTap});

  final Lesion lesion;
  final VoidCallback onTap;

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String get _fecha {
    final f = lesion.fechaCaptura;
    return '${f.day.toString().padLeft(2, '0')} ${_meses[f.month - 1]} ${f.year}';
  }

  Color get _colorRiesgo => switch (lesion.nivelRiesgo?.toLowerCase()) {
    'bajo' => AppColors.riesgoBajo,
    'medio' => AppColors.riesgoMedio,
    'alto' => AppColors.riesgoAlto,
    _ => AppColors.inactivo,
  };

  @override
  Widget build(BuildContext context) {
    // La sombra va por fuera; el fondo blanco lo pinta el Material
    // (si la sombra queda bajo una caja transparente, el fondo se ve gris).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
          BoxShadow(color: Color(0x07000000), spreadRadius: 1),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    lesion.imagenUrl,
                    width: 60,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 60,
                      height: 70,
                      color: AppColors.primarioClaro,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fecha,
                        style: const TextStyle(
                          color: AppColors.textoOscuro,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 12,
                            color: AppColors.textoSecundario,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              lesion.zonaCuerpo ?? 'Zona sin indicar',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Riesgo: ${lesion.nivelRiesgo ?? 'Pendiente'}',
                        style: TextStyle(
                          color: _colorRiesgo,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.inactivo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MensajeEstado extends StatelessWidget {
  const _MensajeEstado({
    required this.icono,
    required this.texto,
    this.accion,
    this.onAccion,
  });

  final IconData icono;
  final String texto;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icono, size: 32, color: AppColors.inactivo),
          const SizedBox(height: 8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textoSecundario,
              fontSize: 14,
            ),
          ),
          if (accion != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAccion, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({required this.indice, required this.onSeleccion});

  final int indice;
  final ValueChanged<int> onSeleccion;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Inicio'),
    (Icons.history, Icons.history, 'Historial'),
    (Icons.handyman_outlined, Icons.handyman, 'Herramientas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.separador)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSeleccion(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            i == indice ? _items[i].$2 : _items[i].$1,
                            size: 22,
                            color: i == indice
                                ? AppColors.primario
                                : AppColors.inactivo,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _items[i].$3,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == indice
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: i == indice
                                  ? AppColors.primario
                                  : AppColors.inactivo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Proximamente extends StatelessWidget {
  const _Proximamente();

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handyman_outlined, size: 40, color: AppColors.inactivo),
            SizedBox(height: 12),
            Text(
              'Herramientas estará disponible pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textoSecundario, fontSize: 14),
            ),
          ],
        ),
      ),
    ),
  );
}
