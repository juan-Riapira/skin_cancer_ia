import 'dart:convert';
import 'package:http/http.dart' as http;

class UsuarioService {
  final String baseUrl = 'http://127.0.0.1:8000';

  Future<bool> registrarUsuario({
    required String nombre,
    required int edad,
    required String genero,
    required Map<String, String> zonaResidencial,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/usuarios');

    try {
      final respuesta = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'edad': edad,
          'genero': genero,
          'zona_residencial': zonaResidencial,
        }),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return true;
      }

      print('Error: ${respuesta.statusCode}');
      print(respuesta.body);

      return false;
    } catch (e) {
      print('Error de conexión: $e');
      return false;
    }
  }
}