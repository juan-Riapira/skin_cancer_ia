import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/lesion.dart';
import '../models/usuario.dart';
import '../utils/app_colors.dart';
import '../utils/formato.dart';
import '../utils/orientacion.dart';
import '../widgets/flujo_widgets.dart';

/// "Resultado del Análisis" (diseño Figma). Muestra la lesión que devolvió
/// el backend. SIMULACIÓN: mientras no haya modelo de IA, el backend
/// responde un análisis por defecto y los textos de hallazgos son fijos
/// por nivel de riesgo (ver [Orientacion]).
class ResultadoAnalisisScreen extends StatelessWidget {
  const ResultadoAnalisisScreen({
    super.key,
    required this.lesion,
    required this.usuario,
    this.imagen,
    this.desdeHistorial = false,
  });

  final Lesion lesion;
  final Usuario? usuario;

  /// Foto en memoria (recién tomada). Si es null se carga desde la URL.
  final Uint8List? imagen;

  /// Abierto desde la lista de registros: oculta "Guardar en Mi Historial"
  /// (ya está guardado) y "atrás" vuelve a la lista.
  final bool desdeHistorial;

  void _volverAInicio(BuildContext context) =>
      Navigator.popUntil(context, (r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final o = Orientacion.de(lesion.nivelRiesgo);
    final zona = lesion.zonaCuerpo ?? 'Sin zona';

    return PopScope(
      // "Atrás" va a Inicio: la foto ya se guardó, no se vuelve a la cámara.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volverAInicio(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.fondoFormulario,
        body: SafeArea(
          child: Column(
            children: [
              BarraFlujo(
                titulo: 'Resultado del Análisis',
                onAtras: () => _volverAInicio(context),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (usuario != null && usuario!.nombre.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: AppColors.textoSecundario,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                usuario!.nombre,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textoOscuro,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      _foto(),
                      const SizedBox(height: 8),
                      Text(
                        'Imagen capturada · $zona · '
                        '${Formato.fechaHora(lesion.fechaCaptura)}',
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _TarjetaOrientacion(lesion: lesion, o: o),
                      const SizedBox(height: 18),
                      _datos(zona),
                      const SizedBox(height: 18),
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color: AppColors.textoOscuro,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Hallazgos de IA',
                            style: TextStyle(
                              color: AppColors.textoOscuro,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        o.hallazgos,
                        style: const TextStyle(
                          color: AppColors.textoSecundario,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _queHacer(o),
                      const SizedBox(height: 18),
                      if (!desdeHistorial) ...[
                        BotonFlujo(
                          texto: 'Guardar en Mi Historial',
                          icono: Icons.bookmark_add_outlined,
                          onPressed: () {
                            // El registro ya quedó guardado en el backend al
                            // enviar la foto; aquí solo se confirma y se vuelve.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Guardado en tu historial.'),
                              ),
                            );
                            _volverAInicio(context);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.acento,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: AppColors.borde),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: generar el PDF del reporte.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Exportar a PDF estará disponible pronto.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 20,
                          ),
                          label: const Text(
                            'Exportar Reporte PDF',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.textoSecundario,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'La orientación de IA no reemplaza un '
                              'diagnóstico profesional. Si la lesión cambia, '
                              'sangra o causa molestias, consulta al '
                              'dermatólogo.',
                              style: TextStyle(
                                color: AppColors.textoSecundario,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _volverAInicio(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.acento,
                          ),
                          icon: const Icon(Icons.home_outlined, size: 16),
                          label: const Text(
                            'Volver a Inicio',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foto() {
    final error = Container(
      height: 180,
      color: AppColors.primarioClaro,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.primario,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: imagen != null
          ? Image.memory(
              imagen!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => error,
            )
          : Image.network(
              lesion.imagenUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => error,
            ),
    );
  }

  Widget _datos(String zona) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borde),
    ),
    child: Row(
      children: [
        Expanded(
          child: _Dato(etiqueta: 'Zona', valor: zona),
        ),
        Expanded(
          child: _Dato(
            etiqueta: 'Fecha',
            valor: Formato.fecha(lesion.fechaCaptura),
          ),
        ),
        Expanded(
          child: _Dato(
            etiqueta: 'ID paciente',
            valor: Formato.idPaciente(lesion.usuarioId),
          ),
        ),
      ],
    ),
  );

  Widget _queHacer(Orientacion o) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FC),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_outline, size: 20, color: AppColors.acento),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Qué hacer ahora?',
                style: TextStyle(color: AppColors.textoOscuro, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                o.recomendacion,
                style: const TextStyle(
                  color: AppColors.textoOscuro,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Tarjeta de color según el riesgo: "Riesgo Bajo · Benigno · 95% Confianza".
class _TarjetaOrientacion extends StatelessWidget {
  const _TarjetaOrientacion({required this.lesion, required this.o});

  final Lesion lesion;
  final Orientacion o;

  @override
  Widget build(BuildContext context) {
    final estiloGrande = TextStyle(
      color: o.titulo,
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.3,
    );
    final estiloPequeno = TextStyle(color: o.acento, fontSize: 13);
    final clasificacion = lesion.clasificacionGeneral ?? lesion.clasificacion;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: o.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: o.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(o.icono, size: 19, color: o.acento),
              const SizedBox(width: 7),
              Text(
                'ORIENTACIÓN DE IA',
                style: TextStyle(
                  color: o.acento,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riesgo ${o.nivel}', style: estiloGrande),
                    if (clasificacion != null)
                      Text(clasificacion, style: estiloPequeno),
                  ],
                ),
              ),
              if (lesion.confianza != null && lesion.confianza! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formato.porcentaje(lesion.confianza),
                      style: estiloGrande,
                    ),
                    Text('Confianza', style: estiloPequeno),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Estimación ilustrativa; no es un diagnóstico confirmado.',
            style: TextStyle(color: o.acento, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        etiqueta,
        style: const TextStyle(color: AppColors.textoSecundario, fontSize: 11),
      ),
      const SizedBox(height: 5),
      Text(
        valor,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.textoOscuro,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}
