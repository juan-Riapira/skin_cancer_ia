import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';
import '../models/lesion.dart';

class LesionService {
  /// Se incrementa cada vez que se guarda una lesión nueva, para que
  /// Inicio recargue su lista al volver.
  static final cambios = ValueNotifier<int>(0);

  static const _tiposImagen = {
    'jpg': 'jpeg',
    'jpeg': 'jpeg',
    'png': 'png',
    'webp': 'webp',
  };

  /// Historial del usuario, ordenado del más reciente al más antiguo
  /// (el backend ya lo ordena por fecha_captura descendente).
  Future<List<Lesion>> listarPorUsuario(String usuarioId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/predictions/usuario/$usuarioId',
    );
    final respuesta = await http.get(url).timeout(ApiConfig.timeout);

    if (respuesta.statusCode != 200) {
      throw Exception('Error ${respuesta.statusCode} al cargar registros');
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List;
    return datos
        .map((e) => Lesion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Envía la foto al backend (POST /api/v1/predictions): se guarda en MinIO
  /// y se crea el registro en MongoDB con su análisis.
  Future<Lesion> crearLesion({
    required String usuarioId,
    required String zonaCuerpo,
    required Uint8List imagen,
    required String nombreArchivo,
  }) async {
    final ext = nombreArchivo.split('.').last.toLowerCase();
    final subtipo = _tiposImagen[ext];
    if (subtipo == null) {
      throw Exception('Formato no permitido. Usa una foto JPG, PNG o WebP.');
    }

    final peticion =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConfig.baseUrl}/api/v1/predictions'),
          )
          ..fields['usuario_id'] = usuarioId
          ..fields['zona_cuerpo'] = zonaCuerpo
          ..files.add(
            http.MultipartFile.fromBytes(
              'imagen',
              imagen,
              filename: nombreArchivo,
              // El backend valida el tipo; sin esto llega como octet-stream.
              contentType: MediaType('image', subtipo),
            ),
          );

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(
        await peticion.send().timeout(const Duration(seconds: 60)),
      );
    } catch (e) {
      debugPrint('Error de conexión al subir imagen: $e');
      throw Exception('No hay conexión con el servidor. Inténtalo de nuevo.');
    }

    if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
      cambios.value++;
      return Lesion.fromJson(
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>,
      );
    }

    debugPrint('Error ${respuesta.statusCode}: ${respuesta.body}');
    throw Exception(switch (respuesta.statusCode) {
      404 => 'El usuario no existe. Vuelve a registrarte.',
      413 => 'La imagen supera 10 MB.',
      415 => 'Formato no permitido. Usa una foto JPG, PNG o WebP.',
      _ => 'No se pudo guardar la imagen (${respuesta.statusCode}).',
    });
  }
}
