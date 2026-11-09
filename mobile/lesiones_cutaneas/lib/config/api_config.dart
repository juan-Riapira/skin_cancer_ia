/// Configuración de conexión con el backend (FastAPI).
///
/// Se puede cambiar al ejecutar sin tocar el código:
///   flutter run --dart-define=API_URL=http://192.168.1.10:8000 \
///               --dart-define=USUARIO_ID=ID_DE_MONGODB
class ApiConfig {
  /// IP local del PC donde corre el backend (uvicorn con --host 0.0.0.0).
  /// El teléfono debe estar en la misma red Wi-Fi.
  /// Si la IP del PC cambia (ver con `hostname -I`), actualízala aquí.
  /// En el emulador de Android también sirve 'http://10.0.2.2:8000'.
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.10:8000',
  );

  /// Usuario cuyos registros se muestran en Inicio.
  /// TEMPORAL: mientras no exista registro/login en la app.
  static const usuarioId = String.fromEnvironment(
    'USUARIO_ID',
    defaultValue: '65f1a2b3c4d5e6f7a8b9c0d1',
  );

  static const timeout = Duration(seconds: 10);

  /// El backend guarda las imágenes con URL de MinIO en "localhost", que
  /// desde el teléfono no existe. Se reemplaza por el host del backend.
  static String urlAccesible(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return uri.replace(host: Uri.parse(baseUrl).host).toString();
    }
    return url;
  }
}
