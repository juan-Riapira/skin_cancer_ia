/// Usuario tal como lo devuelve GET /api/v1/usuarios/{id}.
class Usuario {
  final String id;
  final String nombre;
  final int? edad;
  final String? genero;

  const Usuario({
    required this.id,
    required this.nombre,
    this.edad,
    this.genero,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'] as String,
    nombre: (json['nombre'] as String?)?.trim() ?? '',
    edad: json['edad'] as int?,
    genero: json['genero'] as String?,
  );

  String get primerNombre {
    if (nombre.isEmpty) return '';
    final p = nombre.split(RegExp(r'\s+')).first;
    return p[0].toUpperCase() + p.substring(1);
  }
}
