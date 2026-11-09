import 'package:flutter/material.dart';

import '../models/lesion.dart';
import '../utils/app_colors.dart';
import '../utils/formato.dart';
import '../widgets/cuerpo_interactivo.dart';

/// Pestaña "Historial" de Inicio (diseño Figma "Historial").
/// Lista todas las lesiones del usuario con búsqueda, filtro por zona y orden.
class HistorialView extends StatefulWidget {
  const HistorialView({
    super.key,
    required this.lesiones,
    required this.cargando,
    required this.error,
    required this.onRecargar,
    required this.onAbrir,
  });

  final List<Lesion>? lesiones;
  final bool cargando;
  final String? error;
  final Future<void> Function() onRecargar;
  final ValueChanged<Lesion> onAbrir;

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  static const _todos = 'Todos';

  final _busqueda = TextEditingController();
  String _filtro = _todos;
  bool _recientesPrimero = true;

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  /// Minúsculas y sin tildes, para que "oct" o "espalda" coincidan sin
  /// importar mayúsculas ni acentos.
  static String _normalizar(String s) {
    const con = 'áéíóúüñ';
    const sin = 'aeiouun';
    var r = s.toLowerCase();
    for (var i = 0; i < con.length; i++) {
      r = r.replaceAll(con[i], sin[i]);
    }
    return r;
  }

  List<Lesion> get _visibles {
    final consulta = _normalizar(_busqueda.text.trim());
    final lista = (widget.lesiones ?? []).where((l) {
      final zona = l.zonaCuerpo ?? '';
      if (_filtro != _todos && zona != _filtro) return false;
      if (consulta.isEmpty) return true;
      final texto = _normalizar(
        '$zona ${Formato.fechaHora(l.fechaCaptura)} '
        '${l.clasificacionGeneral ?? ''}',
      );
      return texto.contains(consulta);
    }).toList();
    lista.sort(
      (a, b) => _recientesPrimero
          ? b.fechaCaptura.compareTo(a.fechaCaptura)
          : a.fechaCaptura.compareTo(b.fechaCaptura),
    );
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.lesiones?.length;
    final visibles = _visibles;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: widget.onRecargar,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          children: [
            // Encabezado
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial',
                        style: TextStyle(
                          color: AppColors.textoOscuro,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        total == null
                            ? ' '
                            : '$total ${total == 1 ? 'registro' : 'registros'}',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borde),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: widget.cargando ? null : widget.onRecargar,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.refresh,
                        size: 22,
                        color: AppColors.textoOscuro,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Buscador
            TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por zona o fecha',
                hintStyle: const TextStyle(
                  color: AppColors.textoSecundario,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 19,
                  color: AppColors.textoSecundario,
                ),
                suffixIcon: _busqueda.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_busqueda.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.borde),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.acento),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Filtros por zona (desplazables si no caben)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final z in [_todos, ...ZonaCuerpo.todas]) ...[
                    _Filtro(
                      texto: z,
                      activo: z == _filtro,
                      onTap: () => setState(() => _filtro = z),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tus registros',
                    style: TextStyle(
                      color: AppColors.textoOscuro,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      setState(() => _recientesPrimero = !_recientesPrimero),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_vert,
                          size: 14,
                          color: AppColors.textoSecundario,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _recientesPrimero ? 'Más recientes' : 'Más antiguos',
                          style: const TextStyle(
                            color: AppColors.textoSecundario,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._contenido(visibles),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF4FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 17, color: AppColors.acento),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Benigno y Maligno son diagnósticos clínicos registrados, '
                      'no diagnósticos de la IA. En Revisión indica evaluación '
                      'pendiente.',
                      style: TextStyle(
                        color: AppColors.textoSecundario,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _contenido(List<Lesion> visibles) {
    if (widget.cargando) {
      return const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (widget.error != null) {
      return [
        _Vacio(
          icono: Icons.cloud_off,
          texto: 'No se pudo cargar tu historial.\n${widget.error}',
          accion: 'Reintentar',
          onAccion: widget.onRecargar,
        ),
      ];
    }
    if (visibles.isEmpty) {
      final hayRegistros = (widget.lesiones ?? []).isNotEmpty;
      return [
        _Vacio(
          icono: hayRegistros ? Icons.search_off : Icons.history,
          texto: hayRegistros
              ? 'No hay registros que coincidan con tu búsqueda.'
              : 'Aún no tienes registros.\nLos análisis que hagas aparecerán aquí.',
          accion: hayRegistros ? 'Ver todos' : null,
          onAccion: () => setState(() {
            _busqueda.clear();
            _filtro = _todos;
          }),
        ),
      ];
    }
    return [
      for (final l in visibles) ...[
        _TarjetaHistorial(lesion: l, onTap: () => widget.onAbrir(l)),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _Filtro extends StatelessWidget {
  const _Filtro({
    required this.texto,
    required this.activo,
    required this.onTap,
  });

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
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              texto,
              style: TextStyle(
                color: activo ? Colors.white : AppColors.textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaHistorial extends StatelessWidget {
  const _TarjetaHistorial({required this.lesion, required this.onTap});

  final Lesion lesion;
  final VoidCallback onTap;

  /// Estado clínico: solo se muestra Benigno/Maligno si un profesional lo
  /// validó (`validacion_patologia`); si no, "En revisión".
  (String, Color, Color) get _estado {
    if (!lesion.validacionPatologia) {
      return ('En revisión', const Color(0xFFFFF7ED), const Color(0xFFC2410C));
    }
    final c = (lesion.clasificacionGeneral ?? '').toLowerCase();
    if (c.contains('malign')) {
      return ('Maligno', const Color(0xFFFEF2F2), const Color(0xFFB91C1C));
    }
    if (c.contains('benign')) {
      return ('Benigno', const Color(0xFFECFDF5), const Color(0xFF047857));
    }
    return (
      lesion.clasificacionGeneral ?? 'Validado',
      const Color(0xFFF1F5F9),
      const Color(0xFF475569),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (estado, fondoEstado, colorEstado) = _estado;
    final f = lesion.fechaCaptura;
    final hora =
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';

    // La sombra va por fuera; el fondo blanco lo pinta el Material
    // (si la sombra queda bajo una caja transparente, el fondo se ve gris).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
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
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 68,
                      height: 68,
                      color: AppColors.primarioClaro,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primario,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesion.zonaCuerpo ?? 'Zona sin indicar',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textoOscuro,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${Formato.fecha(f)} · $hora',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: fondoEstado,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          estado,
                          style: TextStyle(
                            color: colorEstado,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
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

class _Vacio extends StatelessWidget {
  const _Vacio({
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
  Widget build(BuildContext context) => Container(
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
            fontSize: 13,
          ),
        ),
        if (accion != null)
          TextButton(onPressed: onAccion, child: Text(accion!)),
      ],
    ),
  );
}
