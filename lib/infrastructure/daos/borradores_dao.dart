import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:moor/moor.dart';
part 'borradores_dao.g.dart';

/// Acceso a los datos de la Bd.
///
/// Incluye los métodos necesarios para  insertar, actualizar, borrar y consultar la información
/// relacionada con las inspecciones y cuestionarios.
@UseDao(tables: [
  /// Definición de las tablas a las que necesitamos acceder para obtener la información
  Activos,
  CuestionarioDeModelos,
  Cuestionarios,
  Bloques,
  Titulos,
  CuadriculasDePreguntas,
  Preguntas,
  OpcionesDeRespuesta,
  Inspecciones,
  Respuestas,
  Contratistas,
  Sistemas,
  SubSistemas,
])
class BorradoresDao extends DatabaseAccessor<Database>
    with _$BorradoresDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  BorradoresDao(Database db) : super(db);

  /// Regresa el total de preguntas respondidas en una inspección con id=[id]
  /// (Se usa en la página de borradores para mostrar el avance)
  Future<int> getTotalRespuesta(int inspeccionId) async {
    final query = await customSelect(
      '''
      SELECT DISTINCT respuestas.pregunta_id  FROM respuestas
      WHERE respuestas.inspeccion_id = $inspeccionId 
      ;''',
    ).map((row) => Respuesta.fromData(row.data, db)).get();
    // Devuelve solo la cantidad
    return query.length;
  }

  /// Devuelve [List<Borrador>] con todas las inspecciones que han sido guardadas
  /// para mostrar en la UI en borradores_screen.dart
  Stream<List<Borrador>> borradores() {
    final query = select(inspecciones).join([
      innerJoin(activos, activos.id.equalsExp(inspecciones.activoId)),
    ])

      /// Se filtran los que tengan momentoEnvio nulo, esto, porque también están quedando guardadas las enviadas para el historial
      /// y estas no se muestran en la pantalla de borradores.
      ..where(isNull(inspecciones.momentoEnvio));

    /// Agrupación del resultado de la consulta en la clase Borrador para manejarlo mejor en la UI
    return query
        .map((row) => Borrador(row.readTable(activos),
            row.readTable(inspecciones), null, null, null))
        .watch()
        .asyncMap<List<Borrador>>(
          (l) async => Future.wait<Borrador>(
            l.map(
              (b) async {
                /// Se consulta el cuestionario asociado a cada inspección, para saber de que tipo es
                final cuestionario = await db.getCuestionario(b.inspeccion);
                return b.copyWith(
                    cuestionario: cuestionario,

                    /// Cantidad de preguntas respondidas
                    avance: await getTotalRespuesta(b.inspeccion.id),

                    /// Total de preguntas del cuestionario
                    total: await db.getTotalPreguntas(cuestionario.id));
              },
            ),
          ),
        );
  }

  /// Elimina la inspección donde inspeccion.id = [borrador.inspeccion.id] y en cascada las respuestas asociadas
  Future eliminarBorrador(Borrador borrador) async {
    await (delete(inspecciones)
          ..where((ins) => ins.id.equals(borrador.inspeccion.id)))
        .go();
  }

  /// Método usado cuando se envía inspección al server que actualiza el momento de envío y
  /// elimina las respuestas
  Future eliminarRespuestas(Borrador borrador) async {
    /// Se está actualizando en la bd porque para el historial, la inspeccion no se va a borrar del cel
    ///  y se necesita el momento de envio como constancia //TODO: implementar historial
    await (update(inspecciones)
          ..where((i) => i.id.equals(borrador.inspeccion.id)))
        .write(
      InspeccionesCompanion(
        momentoEnvio: Value(DateTime.now()),
      ),
    );

    /// Se eliminan las respuestas porque no es necesario para el historial y
    /// no tiene sentido tenerlas ocupando espacio  en la bd
    await (delete(respuestas)
          ..where((res) => res.inspeccionId.equals(borrador.inspeccion.id)))
        .go();
  }

  /// Devuelve Stream con los cuestionarios creados que se usa en cuestionarios_screen.dart
  Stream<List<Cuestionario>> getCuestionarios() =>
      select(cuestionarios).watch();

  /// Elimina el cuestionario con id=[cuestionario.id] y en cascada los bloques, titulos y preguntas asociadas
  Future eliminarCuestionario(Cuestionario cuestionario) async {
    await (delete(cuestionarios)..where((c) => c.id.equals(cuestionario.id)))
        .go();
  }

  /// Devuelve los modelos y el contratista asociado a [cuestionario]
  /// Se usa principalmente a la hora de cargar el borrador del cuestionario para edición
  Future<CuestionarioConContratista> cargarCuestionarioDeModelo(
      Cuestionario cuestionario) async {
    final query = select(cuestionarioDeModelos).join([
      leftOuterJoin(contratistas,
          contratistas.id.equalsExp(cuestionarioDeModelos.contratistaId)),
    ])
      ..where(cuestionarioDeModelos.cuestionarioId.equals(cuestionario.id));

    final res = await query
        .map((row) =>
            [row.readTable(cuestionarioDeModelos), row.readTable(contratistas)])
        .get();

    if (res.isEmpty) return null;

    return CuestionarioConContratista(
        res.map((cu) => cu[0] as CuestionarioDeModelo).toList(),
        res.first[1] as Contratista);
  }
}
