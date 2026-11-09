import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/app_colors.dart';
import '../widgets/flujo_widgets.dart';
import '../widgets/pasos_analisis.dart';
import 'analizando_screen.dart';

/// Paso 3 del flujo de análisis: foto de la lesión (diseño Figma
/// "Captura de Imagen"). Cámara en vivo con guía ovalada, galería y cambio
/// de cámara. Al confirmar, pasa al paso 4 (Analizando), que envía la foto.
class CapturaImagenScreen extends StatefulWidget {
  const CapturaImagenScreen({
    super.key,
    required this.usuarioId,
    required this.zonaCuerpo,
  });

  final String usuarioId;
  final String zonaCuerpo;

  @override
  State<CapturaImagenScreen> createState() => _CapturaImagenScreenState();
}

class _CapturaImagenScreenState extends State<CapturaImagenScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();

  List<CameraDescription> _camaras = [];
  int _indiceCamara = 0;
  CameraController? _camara;
  String? _errorCamara;
  bool _linterna = false;

  // Foto elegida (cámara o galería), pendiente de confirmar.
  Uint8List? _foto;
  String? _nombreFoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciarCamaras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camara?.dispose();
    super.dispose();
  }

  /// Libera la cámara al salir de la app y la recupera al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _camara;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _camara = null;
      _linterna = false;
    } else if (state == AppLifecycleState.resumed) {
      _abrirCamara();
    }
  }

  Future<void> _iniciarCamaras() async {
    try {
      _camaras = await availableCameras();
      if (_camaras.isEmpty) throw CameraException('NoCamera', 'Sin cámara');
      // Empezar con la cámara trasera.
      final trasera = _camaras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _indiceCamara = trasera >= 0 ? trasera : 0;
      await _abrirCamara();
    } catch (e) {
      _mostrarErrorCamara(e);
    }
  }

  Future<void> _abrirCamara() async {
    final anterior = _camara;
    final nueva = CameraController(
      _camaras[_indiceCamara],
      ResolutionPreset.high, // ~1280x720: nítida y liviana para subir
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    setState(() {
      _camara = null;
      _errorCamara = null;
      _linterna = false;
    });
    await anterior?.dispose();
    try {
      await nueva.initialize();
      if (!mounted) return nueva.dispose();
      setState(() => _camara = nueva);
    } catch (e) {
      await nueva.dispose();
      _mostrarErrorCamara(e);
    }
  }

  void _mostrarErrorCamara(Object e) {
    if (!mounted) return;
    final denegado =
        e is CameraException && e.code.toLowerCase().contains('denied');
    setState(
      () => _errorCamara = denegado
          ? 'Permiso de cámara denegado.\nActívalo en Ajustes o usa la Galería.'
          : 'No se pudo abrir la cámara.\nPuedes elegir una foto de la Galería.',
    );
  }

  Future<void> _capturar() async {
    final c = _camara;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      final archivo = await c.takePicture();
      if (_linterna) await c.setFlashMode(FlashMode.off);
      _linterna = false;
      final bytes = await archivo.readAsBytes();
      setState(() {
        _foto = bytes;
        _nombreFoto = 'lesion.jpg';
      });
    } catch (e) {
      _aviso('No se pudo tomar la foto. Inténtalo de nuevo.');
    }
  }

  Future<void> _galeria() async {
    try {
      final archivo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      setState(() {
        _foto = bytes;
        _nombreFoto = archivo.name;
      });
    } catch (e) {
      _aviso('No se pudo abrir la galería.');
    }
  }

  Future<void> _girarCamara() async {
    if (_camaras.length < 2) {
      _aviso('Este teléfono solo tiene una cámara disponible.');
      return;
    }
    _indiceCamara = (_indiceCamara + 1) % _camaras.length;
    await _abrirCamara();
  }

  Future<void> _alternarLinterna() async {
    final c = _camara;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(_linterna ? FlashMode.off : FlashMode.torch);
      setState(() => _linterna = !_linterna);
    } catch (_) {
      _aviso('Esta cámara no tiene linterna.');
    }
  }

  void _repetir() => setState(() {
    _foto = null;
    _nombreFoto = null;
  });

  /// Paso 4: la pantalla "Analizando..." envía la foto al backend.
  void _enviar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalizandoScreen(
          usuarioId: widget.usuarioId,
          zonaCuerpo: widget.zonaCuerpo,
          imagen: _foto!,
          nombreArchivo: _nombreFoto!,
        ),
      ),
    );
  }

  void _aviso(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? AppColors.riesgoAlto : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.oscuroFondo,
      body: SafeArea(
        child: Column(
          children: [
            BarraFlujo(
              titulo: 'Captura de Imagen',
              oscuro: true,
              onAtras: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                child: Column(
                  children: [
                    const PasosAnalisis(pasoActual: 2, oscuro: true),
                    const SizedBox(height: 16),
                    _consejo(),
                    const SizedBox(height: 16),
                    _visor(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          size: 21,
                          color: AppColors.oscuroActivo,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            _foto == null
                                ? 'Asegúrate de contar con buena iluminación y '
                                      'enfocar la lesión a 10 cm'
                                : '¿La lesión se ve nítida y centrada?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _foto == null ? _controles() : _confirmacion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consejo() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.oscuroTarjeta,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 20, color: AppColors.oscuroActivo),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Ubica la mancha en el centro con buena iluminación y a 10 cm '
            'de distancia.',
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ),
      ],
    ),
  );

  /// Visor: cámara en vivo (o foto elegida) con la guía ovalada encima.
  Widget _visor() {
    final oscuroTransparente = AppColors.oscuroFondo.withValues(alpha: .56);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 390,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black, child: _contenidoVisor()),
            ColoredBox(color: AppColors.oscuroFondo.withValues(alpha: .12)),
            // Guía ovalada
            Center(
              child: FractionallySizedBox(
                widthFactor: .67,
                heightFactor: .78,
                child: Container(
                  decoration: ShapeDecoration(
                    shape: OvalBorder(
                      side: BorderSide(
                        width: 3,
                        color: _foto == null
                            ? Colors.white
                            : AppColors.oscuroActivo,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Zona elegida en el paso anterior
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: oscuroTransparente,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, size: 13, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      widget.zonaCuerpo,
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
            // Linterna
            if (_foto == null && _camara != null)
              Positioned(
                right: 16,
                top: 16,
                child: Material(
                  color: oscuroTransparente,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _alternarLinterna,
                    child: SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        _linterna ? Icons.flash_on : Icons.flash_off,
                        size: 18,
                        color: _linterna
                            ? AppColors.oscuroActivo
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (_foto == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.oscuroFondo.withValues(alpha: .63),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Centra la lesión dentro del óvalo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contenidoVisor() {
    if (_foto != null) return Image.memory(_foto!, fit: BoxFit.cover);

    final c = _camara;
    if (c != null && c.value.isInitialized) {
      // La vista previa llega en horizontal: se recorta para llenar el visor.
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: c.value.previewSize?.height ?? 720,
          height: c.value.previewSize?.width ?? 1280,
          child: CameraPreview(c),
        ),
      );
    }

    if (_errorCamara != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: AppColors.oscuroTextoSecundario,
                size: 36,
              ),
              const SizedBox(height: 10),
              Text(
                _errorCamara!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.oscuroTextoSecundario,
                  fontSize: 13,
                ),
              ),
              TextButton(
                onPressed: _iniciarCamaras,
                child: const Text(
                  'Reintentar',
                  style: TextStyle(color: AppColors.oscuroActivo),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const Center(
      child: CircularProgressIndicator(color: AppColors.oscuroActivo),
    );
  }

  /// Galería · Capturar · Girar
  Widget _controles() {
    final listo = _camara != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _BotonSecundario(
          icono: Icons.photo_library_outlined,
          texto: 'Galería',
          onTap: _galeria,
        ),
        Column(
          children: [
            Semantics(
              button: true,
              label: 'Capturar',
              child: GestureDetector(
                onTap: listo ? _capturar : null,
                child: Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(width: 3, color: Colors.white),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: listo ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Capturar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        _BotonSecundario(
          icono: Icons.cameraswitch_outlined,
          texto: 'Girar',
          onTap: listo ? _girarCamara : null,
        ),
      ],
    );
  }

  /// Tras tomar/elegir la foto: repetir o enviar.
  Widget _confirmacion() => Row(
    children: [
      Expanded(
        child: SizedBox(
          height: 54,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppColors.oscuroTextoSecundario),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _repetir,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Repetir'),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: BotonFlujo(
          texto: 'Usar esta foto',
          icono: Icons.check,
          onPressed: _enviar,
        ),
      ),
    ],
  );
}

class _BotonSecundario extends StatelessWidget {
  const _BotonSecundario({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Material(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  icono,
                  size: 23,
                  color: onTap == null ? Colors.white38 : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            texto,
            style: const TextStyle(color: AppColors.pasoInactivo, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
