import 'package:dartz/dartz.dart';
import 'package:inspecciones/core/error/errors.dart';
import 'package:inspecciones/features/llenado_inspecciones/domain/bloques/bloques.dart'
    as bl_dom;
import 'package:inspecciones/features/llenado_inspecciones/domain/bloques/preguntas/preguntas.dart'
    as pr_dom;
import 'package:inspecciones/features/llenado_inspecciones/domain/inspeccion.dart'
    as insp_dom;
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/infrastructure/repositories/fotos_repository.dart';
import 'package:moor/moor.dart';

part 'guardado_inspeccion_dao.moor.dart';

@UseDao(tables: [
  /// Tablas usadas en este DAO
  Inspecciones,
  Respuestas,
])
class GuardadoDeInspeccionDao extends DatabaseAccessor<MoorDatabase>
    with _$GuardadoDeInspeccionDaoMixin {
  GuardadoDeInspeccionDao(MoorDatabase db) : super(db);

  /// Realiza el guardado de la inspección al presionar el botón guardar o finalizar en el llenado.
  Future<void> guardarInspeccion(
    Iterable<bl_dom.Pregunta> preguntasForm,
    insp_dom.Inspeccion inspeccion,
    FotosRepository fotosRepository,
  ) async {
    return transaction(() async {
      await (update(inspecciones)..where((i) => i.id.equals(inspeccion.id)))
          .write(
        InspeccionesCompanion(
          momentoFinalizacion:
              inspeccion.estado == insp_dom.EstadoDeInspeccion.finalizada
                  ? Value(DateTime.now())
                  : const Value.absent(),
          estado: Value(inspeccion.estado),
          criticidadTotal: Value(inspeccion.criticidadTotal),
          criticidadReparacion: Value(inspeccion.criticidadReparacion),
          momentoBorradorGuardado:
              /*  estado == insp_dom.EstadoDeInspeccion.borrador
                  ? const Value.absent()
                  :  */
              //Todo: ¿El momento guardado se actualiza siempre?
              Value(DateTime.now()),
        ),
      );
      final inspeccionId = inspeccion.id;
      await _deleteRespuestas(inspeccionId);

      /// Se comienza a procesar las respuestas a cada pregunta.
      await Future.forEach<bl_dom.Pregunta>(preguntasForm, (pregunta) async {
        //TODO: implementar en un visitor
        if (pregunta is bl_dom.PreguntaDeSeleccionUnica) {
          await _guardarRespuesta(
            pregunta.respuesta!,
            inspeccionId: inspeccionId,
            preguntaId: pregunta.id,
            opcion: pregunta.respuesta!.opcionSeleccionada,
            fotosManager: fotosRepository,
          );
        } else if (pregunta is bl_dom.PreguntaNumerica) {
          await _guardarRespuesta(
            pregunta.respuesta!,
            inspeccionId: inspeccionId,
            preguntaId: pregunta.id,
            valor: pregunta.respuesta!.respuestaNumerica,
            fotosManager: fotosRepository,
          );
        } else if (pregunta is bl_dom.PreguntaDeSeleccionMultiple) {
          await _procesarRespuestaMultiple(
              pregunta.respuestas, inspeccionId, pregunta.id,
              fotosManager: fotosRepository);
        } else if (pregunta is bl_dom.CuadriculaDeSeleccionUnica) {
          await Future.forEach<pr_dom.PreguntaDeSeleccionUnica>(
              pregunta.preguntas,
              (element) async => element.respuesta != null
                  ? await _guardarRespuesta(element.respuesta!,
                      inspeccionId: inspeccionId,
                      preguntaId: element.id,
                      opcion: element.respuesta!.opcionSeleccionada,
                      fotosManager: fotosRepository)
                  : null);
        } else if (pregunta is bl_dom.CuadriculaDeSeleccionMultiple) {
          await Future.forEach<pr_dom.PreguntaDeSeleccionMultiple>(
              pregunta.preguntas,
              (e) async => await _procesarRespuestaMultiple(
                  e.respuestas, inspeccionId, e.id,
                  fotosManager: fotosRepository));
        } else {
          throw TaggedUnionError(pregunta);
        }
      });
    });
  }

  Future<void> _deleteRespuestas(int inspeccionId) => (delete(respuestas)
        ..where((resp) => resp.inspeccionId.equals(inspeccionId)))
      .go();

  Future<void> _guardarRespuesta(
    bl_dom.Respuesta respuesta, {
    required int inspeccionId,
    required int preguntaId,
    double? valor,
    bl_dom.OpcionDeRespuesta? opcion,
    required FotosRepository fotosManager,
  }) async {
    //TODO: hacer tests que verifiquen que si se envia la opcion y el valor cuando
    // el dato es no nulo
    /*if (opcion == null && valor == null) {
      throw ArgumentError(
          "La respuesta debe estar asociada a una opcion o tener un valor");
    }*/

    final fotosBaseProcesadas = await fotosManager.organizarFotos(
      IList.from(respuesta.metaRespuesta.fotosBase),
      Categoria.inspeccion,
      identificador: inspeccionId.toString(),
    );
    final fotosReparacionProcesadas = await fotosManager.organizarFotos(
      IList.from(respuesta.metaRespuesta.fotosReparacion),
      Categoria.inspeccion,
      identificador: inspeccionId.toString(),
    );
    final respuestaAInsertar = RespuestasCompanion.insert(
      //TODO: forma de acceder al id de la pregunta.
      preguntaId: preguntaId,
      inspeccionId: inspeccionId,
      fotosBase: Value(fotosBaseProcesadas),
      fotosReparacion: Value(fotosReparacionProcesadas),
      observacion: Value(respuesta.metaRespuesta.observaciones),
      observacionReparacion:
          Value(respuesta.metaRespuesta.observacionesReparacion),
      reparado: Value(respuesta.metaRespuesta.reparada),
      calificacion: Value(respuesta.metaRespuesta.criticidadInspector),
      opcionDeRespuestaId: Value(opcion?.id),
      valor: Value(valor),
    );

    await into(respuestas).insert(respuestaAInsertar);
  }

  Future _procesarRespuestaMultiple(
      List<bl_dom.SubPreguntaDeSeleccionMultiple> respuesta,
      int inspeccionId,
      int preguntaId,
      {required FotosRepository fotosManager}) async {
    respuesta
        .where((element) =>
            element.respuesta != null && element.respuesta!.estaSeleccionada)
        .map((e) async => await _guardarRespuesta(
              e.respuesta!,
              inspeccionId: inspeccionId,
              preguntaId: preguntaId,
              fotosManager: fotosManager,
              opcion: e.opcion,
            ))
        .toList();
  }

  // funciones para subir al server
  /// Método no usado por ahora
  /* Future<List<RespuestaConOpcionesDeRespuesta2>> getRespuestasDeInspeccion(
      Inspeccion inspeccion) async {
    final query = select(respuestas).join([
      leftOuterJoin(
        opcionesDeRespuesta,
        opcionesDeRespuesta.id.equalsExp(respuestas.opcionDeRespuestaId),
      ),
    ])
      ..where(
        respuestas.inspeccionId.equals(inspeccion.id), //seleccion multiple
      );
    final res = await query
        .map((row) => {
              'respuesta': row.readTable(respuestas),
              'opcionDeRespuesta': row.readTable(opcionesDeRespuesta)
            })
        .get();

    return groupBy(res, (e) => e['respuesta'] as Respuesta)
        .entries
        .map((entry) {
      return RespuestaConOpcionesDeRespuesta2(
        entry.key,
        entry.value
            .map((e) => e['opcionDeRespuesta'] as OpcionDeRespuesta)
            .toList(),
      );
    }).toList();
  } */
}
