import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/usuario.dart';

class UsuarioService {
  /// Registra un usuario y devuelve su id de MongoDB.
  /// Lanza una excepción con un mensaje legible si algo falla.
  Future<String> registrarUsuario({
    required String nombre,
    required int edad,
    required String genero,
    required Map<String, String> zonaResidencial,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/usuarios');

    final http.Response respuesta;
    try {
      respuesta = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nombre': nombre,
              'edad': edad,
              'genero': genero,
              'zona_residencial': zonaResidencial,
            }),
          )
          .timeout(ApiConfig.timeout);
    } catch (e) {
      debugPrint('Error de conexión: $e');
      throw Exception('No hay conexión con el servidor. Inténtalo de nuevo.');
    }

    if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
      final json = jsonDecode(utf8.decode(respuesta.bodyBytes));
      return json['id'] as String;
    }

    debugPrint('Error ${respuesta.statusCode}: ${respuesta.body}');
    if (respuesta.statusCode == 422) {
      throw Exception('Revisa los datos ingresados.');
    }
    throw Exception(
      'No se pudo guardar el registro (${respuesta.statusCode}).',
    );
  }

  /// Obtiene un usuario por id. Lanza excepción si no existe o hay error.
  Future<Usuario> obtenerUsuario(String usuarioId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/usuarios/$usuarioId');
    final respuesta = await http.get(url).timeout(ApiConfig.timeout);

    if (respuesta.statusCode == 404) {
      throw Exception('Usuario no encontrado');
    }
    if (respuesta.statusCode != 200) {
      throw Exception('Error ${respuesta.statusCode} al cargar el usuario');
    }
    return Usuario.fromJson(
      jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>,
    );
  }
}
