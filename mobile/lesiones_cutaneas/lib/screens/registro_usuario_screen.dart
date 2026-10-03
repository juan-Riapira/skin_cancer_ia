import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
final UsuarioService usuarioService = UsuarioService();
class RegistroUsuarioScreen extends StatefulWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  State<RegistroUsuarioScreen> createState() =>
      _RegistroUsuarioScreenState();
}

class _RegistroUsuarioScreenState
    extends State<RegistroUsuarioScreen> {

  final nombreController = TextEditingController();
  final edadController = TextEditingController();
  final generoController = TextEditingController();
  final ubicacionController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    edadController.dispose();
    generoController.dispose();
    ubicacionController.dispose();
    super.dispose();
  }

Future<void> registrarUsuario() async {
  final nombre = nombreController.text;
  final edad = int.tryParse(edadController.text);
  final genero = generoController.text;
  final idUbicacion = int.tryParse(ubicacionController.text);

  if (nombre.isEmpty ||
      edad == null ||
      genero.isEmpty ||
      idUbicacion == null) {
    print('Completa todos los campos');
    return;
  }

  final resultado = await usuarioService.registrarUsuario(
    nombre: nombre,
    edad: edad,
    genero: genero,
    idUbicacion: idUbicacion,
  );

  if (resultado) {
    print('Usuario registrado correctamente');
  } else {
    print('No se pudo registrar el usuario');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registrar usuario"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: "Nombre",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: edadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Edad",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: generoController,
              decoration: const InputDecoration(
                labelText: "Género",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: ubicacionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ID de ubicación",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: registrarUsuario,
                child: const Text("Registrar usuario"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}