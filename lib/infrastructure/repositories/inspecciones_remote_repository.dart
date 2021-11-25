import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:dartz/dartz.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inspecciones/core/entities/app_image.dart';
import 'package:inspecciones/core/error/errors.dart';
import 'package:inspecciones/domain/api/api_failure.dart';
import 'package:inspecciones/features/llenado_inspecciones/domain/cuestionario.dart';
import 'package:inspecciones/features/llenado_inspecciones/domain/domain.dart';
import 'package:inspecciones/features/llenado_inspecciones/domain/identificador_inspeccion.dart';
import 'package:inspecciones/features/llenado_inspecciones/domain/inspeccion.dart';
import 'package:inspecciones/infrastructure/core/typedefs.dart';
import 'package:inspecciones/infrastructure/datasources/fotos_remote_datasource.dart';
import 'package:inspecciones/infrastructure/datasources/providers.dart';
import 'package:inspecciones/utils/future_either_x.dart';
import 'package:path/path.dart' as path;

import '../datasources/inspecciones_remote_datasource.dart';
import '../drift_database.dart' as drift;
import '../utils/transformador_excepciones_api.dart';
import 'fotos_repository.dart';

class InspeccionesRemoteRepository {
  final Reader _read;
  InspeccionesRemoteDataSource get _api =>
      _read(inspeccionesRemoteDataSourceProvider);
  FotosRemoteDataSource get _apiFotos => _read(fotosRemoteDataSourceProvider);
  drift.Database get _db => _read(drift.driftDatabaseProvider);
  FotosRepository get _fotosRepository => _read(fotosRepositoryProvider);

  InspeccionesRemoteRepository(this._read);

  /// Descarga desde el servidor una inspección identificadada con [id] para
  ///  poder continuarla en la app.
  /// retorna Right(unit) si se decargó exitosamente, de ser así, posteriormente
  /// se puede iniciar la inspeccion desde la pantalla de borradores
  Future<Either<ApiFailure, IdentificadorDeInspeccion>> getInspeccionServidor(
      int id) async {
    final inspeccionMap = apiExceptionToApiFailure(
      () => _api.getInspeccion(id),
    );

    /// Al descargarla, se debe guardar en la bd para poder acceder a ella
    return inspeccionMap.nestedEvaluatedMap(
      (ins) => _db.sincronizacionDao.guardarInspeccionBD(ins),
    );
  }

  /// Envia [inspeccion] al server
  Future<Either<ApiFailure, Unit>> subirInspeccion(
      IdentificadorDeInspeccion id) async {
    //TODO: mostrar el progreso en la ui
    final inspeccionCompleta = await _db.cargaDeInspeccionDao.cargarInspeccion(
      cuestionarioId: id.cuestionarioId,
      activoId: id.activo,
      inspectorId: "1", //TODO: traer el id del inspector
    );

    final idFotosSubidas = await _subirFotos(
        inspeccionCompleta.bloques.whereType<Pregunta>().toList());
    final serializador =
        InspeccionSerializer(inspeccionCompleta, idFotosSubidas);
    final inspeccionSerializada = serializador.serializarInspeccion();
    return apiExceptionToApiFailure(
      () => _api
          .subirInspeccion(inspeccionSerializada)
          .then((_) => _db.sincronizacionDao.marcarInspeccionSubida(id))
          .then((_) => unit),
    );
  }

  Future<Map<AppImage, String>> _subirFotos(List<Pregunta> preguntas) async {
    final fotos = <AppImage>[];
    // TODO: usar visitor para hacer este recorrido
    for (final pregunta in preguntas) {
      fotos.addAll(pregunta.respuesta?.metaRespuesta.fotosBase ?? []);
      fotos.addAll(pregunta.respuesta?.metaRespuesta.fotosReparacion ?? []);

      if (pregunta is CuadriculaDeSeleccionUnica) {
        for (final subpregunta in pregunta.preguntas) {
          fotos.addAll(subpregunta.respuesta?.metaRespuesta.fotosBase ?? []);
          fotos.addAll(
              subpregunta.respuesta?.metaRespuesta.fotosReparacion ?? []);
        }
      } else if (pregunta is CuadriculaDeSeleccionMultiple) {
        for (final subPregunta in pregunta.preguntas) {
          fotos.addAll(subPregunta.respuesta?.metaRespuesta.fotosBase ?? []);
          fotos.addAll(
              subPregunta.respuesta?.metaRespuesta.fotosReparacion ?? []);
          for (final opcionDeRespuesta in subPregunta.respuestas) {
            fotos.addAll(
                opcionDeRespuesta.respuesta?.metaRespuesta.fotosBase ?? []);
            fotos.addAll(
                opcionDeRespuesta.respuesta?.metaRespuesta.fotosReparacion ??
                    []);
          }
        }
      } else if (pregunta is PreguntaDeSeleccionMultiple) {
        for (final opcionDeRespuesta in pregunta.respuestas) {
          fotos.addAll(
              opcionDeRespuesta.respuesta?.metaRespuesta.fotosBase ?? []);
          fotos.addAll(
              opcionDeRespuesta.respuesta?.metaRespuesta.fotosReparacion ?? []);
        }
      } else if (pregunta is PreguntaDeSeleccionUnica ||
          pregunta is PreguntaNumerica) {
        // no tienen subpreguntas
      } else {
        throw TaggedUnionError(pregunta);
      }
    }

    final JsonMap resServer = fotos.isEmpty
        ? {}
        : await _api.subirFotosInspeccion(fotos); // nombre: id
    final res = <AppImage, String>{};
    for (final foto in fotos) {
      final id = resServer[_getName(foto)];
      if (id == null) {
        throw Exception("no se encontro el id de la foto");
      }
      res[foto] = id;
    }
    return res;
  }

  String _getName(AppImage foto) {
    var res = path.basename(_getFile(foto).path);
    //MACHETAZO MONUMENTAL
    if (!res.contains(".")) res = "$res.jpg";
    return res;
  }

  XFile _getFile(AppImage foto) => foto.when(
      remote: (_) => XFile(''), //Esto no pasa
      mobile: (f) => XFile(f),
      web: (f) => XFile(f));
}

class InspeccionSerializer {
  final CuestionarioInspeccionado inspeccionCompleta;
  late final Inspeccion inspeccion = inspeccionCompleta.inspeccion;
  late final List<Pregunta> preguntas =
      inspeccionCompleta.bloques.whereType<Pregunta>().toList();
  late final Cuestionario cuestionario = inspeccionCompleta.cuestionario;
  final Map<AppImage, String> idFotosSubidas;

  InspeccionSerializer(this.inspeccionCompleta, this.idFotosSubidas);

  JsonMap serializarInspeccion() {
    final JsonMap res = {};
    res['id'] = inspeccion.id;
    res['cuestionario'] = cuestionario.id;
    res['momento_inicio'] = inspeccion.momentoInicio.toUtc().toIso8601String();
    res['activo'] = inspeccion.activo.id;
    res['respuestas'] = preguntas.map(_serializarPregunta).toList();
    return res;
  }

  JsonMap _serializarPregunta(Pregunta pregunta) {
    final respuesta = pregunta.respuesta;
    final metaRespuesta = respuesta!.metaRespuesta;
    final res = _serializarMetaRespuesta(metaRespuesta);
    res['pregunta'] = pregunta.id;

    if (pregunta is PreguntaDeSeleccionUnica) {
      res.addAll(_serializarRespuestaDeSeleccionUnica(pregunta.respuesta!));
    } else if (pregunta is PreguntaNumerica) {
      final respuesta = pregunta.respuesta!;
      res['tipo_de_respuesta'] = "numerica";
      res['valor_numerico'] = respuesta.respuestaNumerica;
    } else if (pregunta is PreguntaDeSeleccionMultiple) {
      res.addAll(_serializarRespuestaDeSeleccionMultiple(pregunta.respuesta!));
    } else if (pregunta is SubPreguntaDeSeleccionMultiple) {
      final respuesta = pregunta.respuesta!;
      res['pregunta'] = null;
      res['tipo_de_respuesta'] = 'parte_de_seleccion_multiple';
      res['opcion_respondida'] = pregunta.opcion.id;
      res['opcion_respondida_esta_seleccionada'] = respuesta.estaSeleccionada;
    } else if (pregunta is CuadriculaDeSeleccionUnica) {
      final respuesta = pregunta.respuesta!;
      res['tipo_de_respuesta'] = "cuadricula";
      res['subrespuestas_cuadricula'] =
          pregunta.preguntas.map((sub) => _serializarPregunta(sub)).toList();
    } else if (pregunta is CuadriculaDeSeleccionMultiple) {
      final respuesta = pregunta.respuesta!;
      res['tipo_de_respuesta'] = "cuadricula";
      res['subrespuestas_cuadricula'] =
          pregunta.preguntas.map((sub) => _serializarPregunta(sub)).toList();
    } else {
      throw TaggedUnionError(pregunta);
    }
    return res;
  }

  //TODO: revisar
  JsonMap _serializarRespuestaDeSeleccionMultiple(
          RespuestaDeSeleccionMultiple respuesta) =>
      {
        'tipo_de_respuesta': 'seleccion_multiple',
        'subrespuestas_multiple':
            respuesta.opciones.map((sub) => _serializarPregunta(sub)).toList(),
      };

  JsonMap _serializarRespuestaDeSeleccionUnica(
      RespuestaDeSeleccionUnica respuesta) {
    return {
      'tipo_de_respuesta': 'seleccion_unica',
      'opcion_seleccionada': respuesta.opcionSeleccionada!.id,
    };
  }

  JsonMap _serializarMetaRespuesta(MetaRespuesta metaRespuesta) => {
        'reparado': metaRespuesta.reparada,
        'observacion': metaRespuesta.observaciones,
        'observacion_reparacion': metaRespuesta.observacionesReparacion,
        'momento_respuesta':
            metaRespuesta.momentoRespuesta?.toUtc().toIso8601String(),
        'fotos_base': _serializarFotos(metaRespuesta.fotosBase),
        'fotos_reparacion': _serializarFotos(metaRespuesta.fotosReparacion),
      };

  JsonList _serializarFotos(List<AppImage> fotos) =>
      fotos.map((a) => idFotosSubidas[a]).toList();

/*
  JsonMap _serializarPregunta(PreguntaDeSeleccion preguntaCR) {
    final pregunta = preguntaCR.pregunta;
    return {
      'id': pregunta.id,
      'titulo': pregunta.titulo,
      'descripcion': pregunta.descripcion,
      'criticidad': pregunta.criticidad,
      'tipo_de_pregunta': _serializarEnum(pregunta.tipoDePregunta),
    };
  }

  JsonList _serializarCriticidades(List<CriticidadNumerica> criticidades) =>
      criticidades
          .map((criticidad) => {
                'id': criticidad.id,
                'criticidad': criticidad.criticidad,
                'valor_minimo': criticidad.valorMinimo,
                'valor_maximo': criticidad.valorMaximo,
              })
          .toList();

  JsonList _serializarOpcionesDeRespuesta(
          List<OpcionDeRespuesta> opcionesDeRespuesta) =>
      opcionesDeRespuesta
          .map((opcion) => {
                'id': opcion.id,
                'titulo': opcion.titulo,
                'descripcion': opcion.descripcion,
                'criticidad': opcion.criticidad
              })
          .toList();

  String _serializarEnum(dynamic e) =>
      EnumToString.convertToString(e, camelCase: true)
          .toLowerCase()
          .replaceAll(" ", "_");

  JsonList _serializarEtiquetasDeCuestionario(
          List<EtiquetaDeActivo> etiquetas) =>
      etiquetas
          .map((e) => <String, dynamic>{
                'clave': e.clave,
                'valor': e.valor,
              })
          .toList();

  /// ._.
  JsonList _serializarEtiquetasDePregunta(List<EtiquetaDePregunta> etiquetas) =>
      etiquetas
          .map((e) => <String, dynamic>{
                'clave': e.clave,
                'valor': e.valor,
              })
          .toList();*/
}
