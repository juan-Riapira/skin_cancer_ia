import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/usuario_service.dart';
import '../utils/app_colors.dart';
import '../widgets/flujo_widgets.dart';
import '../widgets/pasos_analisis.dart';
import 'ubicacion_lesion_screen.dart';

/// Paso 1 del flujo de análisis: datos de la persona (diseño Figma
/// "Registro de usuario"). Al guardar, pasa al paso 2 (Ubicación) y
/// devuelve a Inicio el id del usuario creado en el backend.
class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  static const _generos = ['Femenino', 'Masculino', 'Otro'];
  static const _departamentos = ['Boyacá'];
  static const _municipios = ['Sogamoso', 'Tunja', 'Duitama'];
  static const _otroMunicipio = 'Otro';

  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _edad = TextEditingController();
  final _vereda = TextEditingController();
  final _municipioOtro = TextEditingController();
  final _servicio = UsuarioService();

  String _departamento = _departamentos.first;
  String? _genero;
  String? _municipio;
  bool _intentoEnviar = false;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _vereda.dispose();
    _municipioOtro.dispose();
    super.dispose();
  }

  String? get _municipioFinal =>
      _municipio == _otroMunicipio ? _municipioOtro.text.trim() : _municipio;

  Future<void> _continuar() async {
    FocusScope.of(context).unfocus();
    setState(() => _intentoEnviar = true);

    final formularioOk = _formKey.currentState!.validate();
    if (!formularioOk || _genero == null || _municipio == null) return;

    setState(() => _guardando = true);
    try {
      final id = await _servicio.registrarUsuario(
        nombre: _nombre.text.trim(),
        edad: int.parse(_edad.text.trim()),
        genero: _genero!,
        zonaResidencial: {
          'departamento': _departamento,
          'municipio': _municipioFinal!,
          if (_vereda.text.trim().isNotEmpty) 'vereda': _vereda.text.trim(),
        },
      );
      if (!mounted) return;
      // Paso 2. `result: id` devuelve el id a Inicio de inmediato, y "atrás"
      // desde Ubicación vuelve a Inicio (no al formulario ya guardado).
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UbicacionLesionScreen(usuarioId: id)),
        result: id,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.riesgoAlto,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondoFormulario,
      body: SafeArea(
        child: Column(
          children: [
            BarraFlujo(
              onAtras: _guardando ? null : () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 38),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PasosAnalisis(pasoActual: 0),
                      const SizedBox(height: 14),
                      const Text(
                        'Datos de la persona a revisar',
                        style: TextStyle(
                          color: AppColors.textoOscuro,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Completa esta información para adaptar el análisis '
                        'a la piel de quien realiza la consulta.',
                        style: TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Etiqueta('Nombre Completo'),
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: _decoracion('Camila Rojas'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Escribe el nombre'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      _Etiqueta('Edad'),
                      TextFormField(
                        controller: _edad,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _decoracion(
                          '32',
                          icono: Icons.calendar_today_outlined,
                        ),
                        validator: (v) {
                          final edad = int.tryParse(v?.trim() ?? '');
                          if (edad == null) return 'Escribe la edad';
                          if (edad > 120) return 'Edad no válida';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _Etiqueta('Género', espacio: 9),
                      OpcionesChips(
                        opciones: _generos,
                        seleccion: _genero,
                        onSeleccion: (g) => setState(() => _genero = g),
                      ),
                      if (_intentoEnviar && _genero == null)
                        const _TextoError('Selecciona el género'),
                      const SizedBox(height: 30),
                      const Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            size: 18,
                            color: AppColors.textoOscuro,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Zona Residencial',
                            style: TextStyle(
                              color: AppColors.textoOscuro,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Etiqueta('Departamento'),
                      DropdownButtonFormField<String>(
                        initialValue: _departamento,
                        icon: const Icon(
                          Icons.expand_more,
                          size: 18,
                          color: AppColors.textoSecundario,
                        ),
                        decoration: _decoracion(null),
                        style: const TextStyle(
                          color: AppColors.textoOscuro,
                          fontSize: 14,
                        ),
                        items: [
                          for (final d in _departamentos)
                            DropdownMenuItem(value: d, child: Text(d)),
                        ],
                        onChanged: (d) => setState(() => _departamento = d!),
                      ),
                      const SizedBox(height: 14),
                      _Etiqueta('Municipio', espacio: 8),
                      OpcionesChips(
                        opciones: const [..._municipios, _otroMunicipio],
                        seleccion: _municipio,
                        onSeleccion: (m) => setState(() => _municipio = m),
                      ),
                      if (_intentoEnviar && _municipio == null)
                        const _TextoError('Selecciona el municipio'),
                      if (_municipio == _otroMunicipio) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _municipioOtro,
                          textCapitalization: TextCapitalization.words,
                          decoration: _decoracion('Escribe el municipio'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Escribe el municipio'
                              : null,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _Etiqueta('Vereda / Barrio'),
                      TextFormField(
                        controller: _vereda,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        decoration: _decoracion(
                          'Barrio El Rosario',
                          icono: Icons.place_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),
                      BotonFlujo(
                        texto: 'Continuar al análisis',
                        icono: Icons.arrow_forward,
                        cargando: _guardando,
                        onPressed: _continuar,
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: AppColors.textoSecundario,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Esta información se usa únicamente para '
                              'contextualizar el análisis de la piel y no será '
                              'compartida con terceros.',
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
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoracion(String? hint, {IconData? icono}) {
    OutlineInputBorder borde(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.textoSecundario,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      suffixIcon: icono == null
          ? null
          : Icon(icono, size: 18, color: AppColors.textoSecundario),
      enabledBorder: borde(AppColors.borde),
      focusedBorder: borde(AppColors.acento),
      errorBorder: borde(AppColors.riesgoAlto),
      focusedErrorBorder: borde(AppColors.riesgoAlto),
    );
  }
}

// ---------------------------------------------------------------------------

class _Etiqueta extends StatelessWidget {
  const _Etiqueta(this.texto, {this.espacio = 7});

  final String texto;
  final double espacio;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: espacio),
    child: Text(
      texto,
      style: const TextStyle(
        color: AppColors.textoOscuro,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _TextoError extends StatelessWidget {
  const _TextoError(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      texto,
      style: const TextStyle(color: AppColors.riesgoAlto, fontSize: 12),
    ),
  );
}
