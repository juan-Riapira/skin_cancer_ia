import 'dart:convert';
import 'package:http/http.dart' as http;

class UsuarioService {
  final String baseUrl = 'http://127.0.0.1:8000';

  Future<bool> registrarUsuario({
    required String nombre,
    required int edad,
    required String genero,
    required int idUbicacion,
  }) async {
    final url = Uri.parse('$baseUrl/api/usuarios');

    final respuesta = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'edad': edad,
        'genero': genero,
        'id_ubicacion': idUbicacion,
      }),
    );

    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
      return true;
    }

    print('Error: ${respuesta.statusCode}');
    print(respuesta.body);

    return false;
  }
}