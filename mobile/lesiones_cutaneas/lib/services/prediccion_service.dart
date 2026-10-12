import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config.dart';

class PrediccionService {
  /// Sube la imagen y crea la lesión. Devuelve el JSON de la respuesta o null si falló.
  Future<Map<String, dynamic>?> crearPrediccion({
    required String usuarioId,
    required String zonaCuerpo,
    required File imagen,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/predictions');

    final ext = imagen.path.split('.').last.toLowerCase();
    final subtipo = ext == 'png' ? 'png' : (ext == 'webp' ? 'webp' : 'jpeg');

    final request = http.MultipartRequest('POST', uri)
      ..fields['usuario_id'] = usuarioId
      ..fields['zona_cuerpo'] = zonaCuerpo
      ..files.add(await http.MultipartFile.fromPath(
        'imagen',
        imagen.path,
        contentType: MediaType('image', subtipo),
      ));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final respuesta = await http.Response.fromStream(streamed);

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
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