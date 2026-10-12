import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class UsuarioService {
  /// Devuelve el id del usuario creado, o null si falló.
  Future<String?> registrarUsuario({
    required String nombre,
    required int edad,
    required String genero,
    required Map<String, String> zonaResidencial,
  }) async {
    final url = Uri.parse('$apiBaseUrl/api/v1/usuarios');

    try {
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'edad': edad,
          'genero': genero,
          'zona_residencial': zonaResidencial,
        }),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final data = jsonDecode(utf8.decode(respuesta.bodyBytes));
        final id = data['_id'] ?? data['id'];
        if (id == null) {
          print('Registro OK pero no vino el id: ${respuesta.body}');
        }
        return id?.toString();
      }

      print('Error: ${respuesta.statusCode}');
      print(respuesta.body);
      return null;
    } catch (e) {
      print('Error de conexión: $e');
      return null;
    }
  }
}