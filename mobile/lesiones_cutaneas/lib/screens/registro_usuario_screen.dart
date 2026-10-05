import 'package:flutter/material.dart';
import '../services/usuario_service.dart';

final UsuarioService usuarioService = UsuarioService();

class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() => _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState extends State<RegistroUsuarioScreen> {
  final nombreController = TextEditingController();
  final edadController = TextEditingController();
  final veredaController = TextEditingController();

  static const List<String> generos = [
    'Masculino',
    'Femenino',
    'Binario',
    'No binario',
    'Otro',
    'Prefiero no decir',
  ];

  // Municipios de la Provincia de Sugamuxi (Boyacá)
  static const List<String> municipiosSugamuxi = [
    'Aquitania',
    'Cuítiva',
    'Firavitoba',
    'Gámeza',
    'Iza',
    'Mongua',
    'Monguí',
    'Nobsa',
    'Pesca',
    'Sogamoso',
    'Tibasosa',
    'Tópaga',
    'Tota',
  ];

  static const String departamento = 'Boyacá';

  String? generoSeleccionado;
  String? municipioSeleccionado;
  bool cargando = false;

  @override
  void dispose() {
    nombreController.dispose();
    edadController.dispose();
    veredaController.dispose();
    super.dispose();
  }

  void mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> registrarUsuario() async {
    final nombre = nombreController.text.trim();
    final edad = int.tryParse(edadController.text.trim());
    final vereda = veredaController.text.trim();

    if (nombre.isEmpty ||
        edad == null ||
        generoSeleccionado == null ||
        municipioSeleccionado == null ||
        vereda.isEmpty) {
      mostrarMensaje('Completa todos los campos');
      return;
    }

    setState(() => cargando = true);

    final resultado = await usuarioService.registrarUsuario(
      nombre: nombre,
      edad: edad,
      genero: generoSeleccionado!,
      zonaResidencial: {
        'departamento': departamento,
        'municipio': municipioSeleccionado!,
        'vereda': vereda,
      },
    );

    if (!mounted) return;
    setState(() => cargando = false);

    mostrarMensaje(resultado
        ? 'Usuario registrado correctamente'
        : 'No se pudo registrar el usuario');
  }

  InputDecoration _decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3F1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera negra curva
            ClipPath(
              clipper: _CabeceraClipper(),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'S L A T E',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: 3,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Crea tu cuenta para continuar.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registro',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
                  ),

                  // Nombre
                  _etiqueta('Nombre'),
                  TextField(
                    controller: nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoracion('Ingresa tu nombre'),
                  ),

                  // Edad
                  _etiqueta('Edad'),
                  TextField(
                    controller: edadController,
                    keyboardType: TextInputType.number,
                    decoration: _decoracion('Ingresa tu edad'),
                  ),

                  // Género (select)
                  _etiqueta('Género'),
                  DropdownButtonFormField<String>(
                    value: generoSeleccionado,
                    decoration: _decoracion('Selecciona tu género'),
                    borderRadius: BorderRadius.circular(14),
                    items: generos
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (valor) =>
                        setState(() => generoSeleccionado = valor),
                  ),

                  const SizedBox(height: 28),
                  const Text(
                    'Zona residencial',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),

                  // Departamento (fijo en Boyacá)
                  _etiqueta('Departamento'),
                  TextFormField(
                    initialValue: departamento,
                    readOnly: true,
                    enabled: false,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _decoracion(''),
                  ),

                  // Municipio (Sugamuxi)
                  _etiqueta('Municipio'),
                  DropdownButtonFormField<String>(
                    value: municipioSeleccionado,
                    decoration: _decoracion('Selecciona tu municipio'),
                    borderRadius: BorderRadius.circular(14),
                    items: municipiosSugamuxi
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (valor) =>
                        setState(() => municipioSeleccionado = valor),
                  ),

                  // Vereda (texto)
                  _etiqueta('Vereda'),
                  TextField(
                    controller: veredaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoracion('Escribe tu vereda'),
                  ),

                  const SizedBox(height: 32),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: cargando ? null : registrarUsuario,
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
                          : const Text('Registrar usuario',
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

// Curva de la cabecera negra
class _CabeceraClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.05,
      size.width,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}