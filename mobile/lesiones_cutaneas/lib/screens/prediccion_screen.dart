import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/prediccion_service.dart';
import '../widgets/cabecera_curva.dart';

class PrediccionScreen extends StatefulWidget {
  final String usuarioId;
  const PrediccionScreen({super.key, required this.usuarioId});

  @override
  State<PrediccionScreen> createState() => _PrediccionScreenState();
}

class _PrediccionScreenState extends State<PrediccionScreen> {
  final _servicio = PrediccionService();
  final _picker = ImagePicker();

  static const List<String> zonasCuerpo = [
    'Rostro',
    'Cuero cabelludo',
    'Cuello',
    'Pecho',
    'Abdomen',
    'Espalda',
    'Brazo',
    'Antebrazo',
    'Mano',
    'Pierna',
    'Pie',
  ];

  File? imagen;
  String? zonaSeleccionada;
  bool cargando = false;

  // Campos que llena el modelo; mientras tanto muestran "Pendiente"
  final clasificacionCtrl = TextEditingController(text: 'Pendiente');
  final riesgoCtrl = TextEditingController(text: 'Pendiente');
  final confianzaCtrl = TextEditingController(text: 'Pendiente');
  final arquitecturaCtrl = TextEditingController(text: 'Pendiente');
  final validacionCtrl = TextEditingController(text: 'Pendiente');

  @override
  void dispose() {
    clasificacionCtrl.dispose();
    riesgoCtrl.dispose();
    confianzaCtrl.dispose();
    arquitecturaCtrl.dispose();
    validacionCtrl.dispose();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    final archivo = await _picker.pickImage(
      source: fuente,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (archivo != null) {
      setState(() => imagen = File(archivo.path));
    }
  }

  void _elegirOrigen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> enviar() async {
    if (imagen == null || zonaSeleccionada == null) {
      mostrarMensaje('Selecciona una imagen y la zona del cuerpo');
      return;
    }

    setState(() => cargando = true);

    final resultado = await _servicio.crearPrediccion(
      usuarioId: widget.usuarioId,
      zonaCuerpo: zonaSeleccionada!,
      imagen: imagen!,
    );

    if (!mounted) return;
    setState(() => cargando = false);

    if (resultado == null) {
      mostrarMensaje('No se pudo guardar la lesión');
      return;
    }

    _mostrarResultado(resultado);
    mostrarMensaje('Lesión guardada correctamente');
  }

  /// Rellena los campos con lo que devuelva el backend; "Pendiente" si no hay análisis real.
  void _mostrarResultado(Map<String, dynamic> r) {
    final analisis = r['analisis_dermatologica'] as Map<String, dynamic>?;
    final res = analisis?['resultados'] as Map<String, dynamic>?;

    String texto(dynamic v) {
      final s = v?.toString() ?? '';
      return (s.isEmpty || s == 'Pendiente') ? 'Pendiente' : s;
    }

    final analizada = texto(analisis?['clasificacion']) != 'Pendiente';
    final conf = res?['confianza'];

    setState(() {
      clasificacionCtrl.text = texto(analisis?['clasificacion']);
      riesgoCtrl.text = texto(res?['nivel_riesgo']);
      arquitecturaCtrl.text = texto(res?['arquitectura']);
      confianzaCtrl.text = (analizada && conf is num)
          ? '${(conf * 100).toStringAsFixed(1)} %'
          : 'Pendiente';
      validacionCtrl.text =
          analisis?['validacion_patologia'] == true ? 'Validada' : 'Pendiente';
    });
  }

  InputDecoration _decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _campoPendiente(String etiqueta, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(etiqueta),
        TextField(
          controller: controller,
          enabled: false,
          style: const TextStyle(color: Colors.black54),
          decoration: _decoracion(''),
        ),
      ],
    );
  }

  Widget _selectorImagen() {
    return GestureDetector(
      onTap: _elegirOrigen,
      child: Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagen == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.black38),
                  SizedBox(height: 8),
                  Text('Toca para agregar una imagen',
                      style: TextStyle(color: Colors.black38)),
                ],
              )
            : Image.file(imagen!, fit: BoxFit.cover),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CabeceraCurva(subtitulo: 'Analiza una lesión cutánea.'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nueva lesión',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                  ),

                  _etiqueta('Imagen de la lesión'),
                  _selectorImagen(),

                  _etiqueta('Zona del cuerpo'),
                  DropdownButtonFormField<String>(
                    value: zonaSeleccionada,
                    decoration: _decoracion('Selecciona la zona'),
                    borderRadius: BorderRadius.circular(14),
                    items: zonasCuerpo
                        .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                        .toList(),
                    onChanged: (valor) => setState(() => zonaSeleccionada = valor),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Análisis dermatológico',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),

                  _campoPendiente('Clasificación', clasificacionCtrl),
                  _campoPendiente('Nivel de riesgo', riesgoCtrl),
                  _campoPendiente('Confianza', confianzaCtrl),
                  _campoPendiente('Arquitectura', arquitecturaCtrl),
                  _campoPendiente('Validación patológica', validacionCtrl),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: cargando ? null : enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: cargando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Guardar lesión',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}