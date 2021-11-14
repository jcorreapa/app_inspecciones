/// Definición de todos los Controllers de los bloques en la creación de cuestionarios
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:inspecciones/core/entities/app_image.dart';
import 'package:inspecciones/infrastructure/drift_database.dart';
import 'package:inspecciones/infrastructure/repositories/cuestionarios_repository.dart';
import 'package:reactive_forms/reactive_forms.dart';

import 'creacion_validators.dart';
import 'tablas_unidas.dart';

/// Interfaz de todos los controllers involucrados en la creación de cuestionarios
@immutable
abstract class CreacionController {
  /// Objeto de la librería reactive forms, por ahora todos son [FormGroup] pero
  /// de llegar el caso se puede abstraer a [AbstractControl]
  FormGroup get control;

  /// Crea un control del mismo tipo usando los datos ingresados en este,
  /// Importante: Se deben eliminar ([Value.absent]) las referencias unicas
  /// tales como id y bloqueId
  CreacionController copy();

  /// Devuelve la información obtenida en forma de un objeto que
  /// será usado para persistir la información en el repositorio local
  /// ! Buscar la manera de definir tagged union types para que sea imposible enviar
  /// objetos que la Database no pueda tratar, por ahora basta con fijarse que la DB
  /// trate todos los posibles objetos retornados por los metodos [toDB].
  Object toDB();

  /// Libera los recursos de este control
  void dispose() {
    /// creo que no va a ser falta porque al insertarlo en un formgroup superior,
    /// este va a hacer dispose de todo (o deberia)
    control.dispose();
  }
}

mixin ConRespuestas {
  List<CreadorRespuestaController> get controllersRespuestas;
  FormArray<Map<String, dynamic>> get respuestasControl;

  /// Añade una opcion de respuesta a los controles

  void agregarRespuesta() {
    final nuevoController = CreadorRespuestaController();
    controllersRespuestas.add(nuevoController);
    respuestasControl.add(nuevoController.control);
  }

  /// Elimina de los controles, la opcion de respuesta [c]

  void borrarRespuesta(CreacionController c) {
    controllersRespuestas.remove(c);
    respuestasControl.remove(c.control);
  }
}

/// Crea o edita un titulo en un cuestionario
/// Si [tituloCompanion] no es null, se insertan los valores de sus campos en el control
/// y se guarda su id para editarlo en la db
/// si es nulo se establecen unos valores por defecto

class CreadorTituloController extends CreacionController {
  final TitulosCompanion _tituloCompanion;

  late final tituloControl = fb.control<String>(
    _tituloCompanion.titulo.valueOrDefault(" "),
    [Validators.required],
  );
  late final descripcionControl = fb.control<String>(
    _tituloCompanion.descripcion.valueOrDefault(""),
  );
  late final fotosControl = fb.control<List<AppImage>>(
    _tituloCompanion.fotos.valueOrDefault([]).toList(),
  );

  @override
  late final control = FormGroup({
    'titulo': tituloControl,
    'descripcion': descripcionControl,
    'fotos': fotosControl,
  });

  /// Recibe el companion de un titulo el cual puede(O DEBE?) contener valores
  /// por defecto para los campos, si incluye la id, el control será actualizado
  /// en la db con la misma id
  CreadorTituloController([this._tituloCompanion = const TitulosCompanion()]);

  @override
  CreadorTituloController copy() {
    return CreadorTituloController(
      toDB().copyWith(
        id: const Value.absent(),
        bloqueId: const Value.absent(),
      ),
    );
  }

  /// En caso de que ya exista, se actualiza con los nuevos valores introducidos
  /// en el formulario, (Como ya tenemos un titulo, se actualiza en la bd)
  /// Este método es usado a la hora de guardar el cuestionario en la bd.
  /// Devuelve un [TitulosCompanion] usando el constructor
  /// [TitulosCompanion.insert] pero como no sabemos el bloqueId todavia se debe usar
  /// el constructor normal de companion, pero para insertar mas adelante se deberia
  /// usar el constructor [TitulosCompanion.insert] para asegurarse que todo esté bien.

  @override
  TitulosCompanion toDB() {
    return _tituloCompanion.copyWith(
      titulo: Value(tituloControl.value!),
      descripcion: Value(descripcionControl.value!),
      fotos: Value(fotosControl.value!),
    );
  }
}

///  Control encargado de manejar las preguntas de tipo selección
class CreadorPreguntaController extends CreacionController with ConRespuestas {
  final CuestionariosRepository _repository;

  /// Si se llama al agregar un nuevo bloque (desde [BotonesBloque]), [datosIniciales] es null,
  /// Cuando se va a editar, [datosIniciales] es pasado directamente desde el
  /// controller superior.
  /// Cuando se usa copiar, [datosIniciales] se obtiene desde el método [toDataClass()]
  final PreguntaConOpcionesDeRespuestaCompanion datosIniciales;

  /// Diferencia las de selección y las que son de cuadricula
  final bool parteDeCuadricula;
  final bool esNumerica;

  late final criticidadControl = fb.control<double>(
      datosIniciales.pregunta.criticidad.valueOrDefault(0).toDouble());

  late final fotosGuiaControl = fb.control<List<AppImage>>(
    datosIniciales.pregunta.fotosGuia.valueOrDefault([]).toList(),
  );

  /// Son las opciones de respuesta.
  /// Si el bloque es nuevo, son null y se pasa un FormArray vacío.
  /// Si es bloque copiado o viene de edición se pasa un FormArray con cada
  /// una de las opciones que ya existen para la pregutna
  @override
  late final controllersRespuestas = datosIniciales.opcionesDeRespuesta
      .map((e) => CreadorRespuestaController(e))
      .toList();

  @override
  late final respuestasControl = fb.array<Map<String, dynamic>>(
    controllersRespuestas.map((e) => e.control).toList(),

    /// Si es parte de cuadricula o numérica no tienen opciones de respuesta
    [if (!parteDeCuadricula && !esNumerica) Validators.minLength(1)],
  );

  @override
  late final control = fb.group({
    'general': camposGeneralesControl,
    'criticidad': criticidadControl,
    'fotosGuia': fotosGuiaControl,
    'respuestas': respuestasControl,
  });

  final CamposGeneralesPreguntaController controllerCamposGenerales;
  late final camposGeneralesControl = controllerCamposGenerales.control;

  CreadorPreguntaController(
    this._repository, {
    this.datosIniciales = const PreguntaConOpcionesDeRespuestaCompanion.vacio(),
    this.parteDeCuadricula = false,
    this.esNumerica = false,
  }) : controllerCamposGenerales = CamposGeneralesPreguntaController(
          tituloInicial: datosIniciales.pregunta.titulo,
          descripcionInicial: datosIniciales.pregunta.descripcion,
          etiquetasIniciales: Value(datosIniciales.etiquetas),
          tipoInicial: datosIniciales.pregunta.tipoDePregunta,
          parteDeCuadricula: parteDeCuadricula,
        );

  @override
  CreadorPreguntaController copy() {
    final copied = toDB();

    return CreadorPreguntaController(
      _repository,
      datosIniciales: copied.copyWith(
        pregunta: copied.pregunta.copyWith(
          id: const Value.absent(),
          bloqueId: const Value.absent(),
        ),
        opcionesDeRespuesta: copied.opcionesDeRespuesta
            .map((o) => o.copyWith(
                  id: const Value.absent(),
                  preguntaId: const Value.absent(),
                ))
            .toList(),
        etiquetas: [...copied.etiquetas],
      ),
    );
  }

  /// En caso de que ya exista [datosIniciales], se actualiza con los nuevos
  /// valores introducidos en el formulario, (Como ya tiene id, se actualiza en la bd)
  /// Si no se "crea" uno con el método [toDataClass()]
  /// Este método es usado a la hora de guardar el cuestionario en la bd.
  @override
  PreguntaConOpcionesDeRespuestaCompanion toDB() {
    final g = controllerCamposGenerales; // alias para escribir menos
    return PreguntaConOpcionesDeRespuestaCompanion(
        datosIniciales.pregunta.copyWith(
          titulo: Value(g.tituloControl.value!),
          descripcion: Value(g.descripcionControl.value!),
          tipoDePregunta: Value(g.tipoDePreguntaControl.value!),
          criticidad: Value(criticidadControl.value!.round()),
          fotosGuia: Value(fotosGuiaControl.value!),
        ),
        controllersRespuestas.map((e) => e.toDB()).toList(),
        g.etiquetasControl.value!
            .map((e) => EtiquetasDePreguntaCompanion.insert(
                clave: e.split(":").first, valor: e.split(":").last))
            .toList());
  }
}

/// Control encargado de manejar la creación de opciones de respuesta en preguntas de selección o de cuadricula
class CreadorRespuestaController extends CreacionController {
  /// Si se llama al agregar criticidad (desde la cración de pregunta numerica), [_respuestaDesdeDB] es null,
  /// Cuando se va a editar, [_respuestaDesdeDB] es pasado directamente desde los BloquesBd de [CreacionFormViewModel.cargarBloques()]
  /// Cuando se usa copiar, [_respuestaDesdeDB] se obtiene desde el método [toDataClass()]
  final OpcionesDeRespuestaCompanion _respuestaDesdeDB;

  late final tituloControl = fb.control<String>(
    _respuestaDesdeDB.titulo.valueOrDefault(""),
    [Validators.required],
  );
  late final descripcionControl = fb.control<String>(
    _respuestaDesdeDB.descripcion.valueOrDefault(""),
    [Validators.required],
  );
  late final criticidadControl = fb.control<double>(
      _respuestaDesdeDB.criticidad.valueOrDefault(0).toDouble());

  @override
  late final control = fb.group({
    'titulo': tituloControl,
    'descripcion': descripcionControl,
    'criticidad': criticidadControl,
  });

  CreadorRespuestaController(
      [this._respuestaDesdeDB = const OpcionesDeRespuestaCompanion()]);

  @override
  CreadorRespuestaController copy() {
    return CreadorRespuestaController(
      toDB().copyWith(id: const Value.absent()),
    );
  }

  @override
  OpcionesDeRespuestaCompanion toDB() {
    return _respuestaDesdeDB.copyWith(
        titulo: Value(tituloControl.value!),
        descripcion: Value(descripcionControl.value!),
        criticidad: Value(criticidadControl.value!.round()));
  }
}

/// Controller que maneja la creación de rangoss de criticidad para preguntas numericas
class CreadorCriticidadesNumericasController extends CreacionController {
  final CriticidadesNumericasCompanion _criticidadDB;

  late final minimoControl = fb.control<double>(
    _criticidadDB.valorMinimo.valueOrDefault(0),
    [Validators.required],
  );
  late final maximoControl = fb.control<double>(
    _criticidadDB.valorMaximo.valueOrDefault(0),
    [Validators.required],
  );
  late final criticidadControl =
      fb.control<double>(_criticidadDB.criticidad.valueOrDefault(0).toDouble());

  @override
  late final FormGroup control;

  CreadorCriticidadesNumericasController(
      [this._criticidadDB = const CriticidadesNumericasCompanion()]) {
    //No se puede inicializar en el late porque si nunca se usa el control, los
    //validators generales no se van a crear.
    // TODO: arreglar todos los otros controls de la app que sufran de este problema
    control = fb.group({
      'minimo': minimoControl,
      'maximo': maximoControl,
      'criticidad': criticidadControl,
    }, [
      /// Que el valor mínimo sea menor que el introducido en máximo
      //TODO: validación para que no se entrecrucen los rangos
      verificarRango(controlMinimo: minimoControl, controlMaximo: maximoControl)
    ]);
  }

  @override
  CreadorCriticidadesNumericasController copy() {
    return CreadorCriticidadesNumericasController(
      toDB().copyWith(id: const Value.absent()),
    );
  }

  @override
  CriticidadesNumericasCompanion toDB() {
    return _criticidadDB.copyWith(
      valorMinimo: Value(minimoControl.value!),
      valorMaximo: Value(maximoControl.value!),
      criticidad: Value(criticidadControl.value!.round()),
    );
  }
}

extension PreguntaPorDefecto on List<PreguntaConOpcionesDeRespuestaCompanion> {
  PreguntaConOpcionesDeRespuestaCompanion get firstOrDefault =>
      firstWhere((_) => true,
          orElse: () => const PreguntaConOpcionesDeRespuestaCompanion.vacio());
}

///TODO: reducir la duplicacion de codigo con la pregunta normal
class CreadorPreguntaCuadriculaController extends CreacionController
    with ConRespuestas {
  final CuestionariosRepository _repository;

  /// Info cuadricula y opciones de respuesta
  final CuadriculaConPreguntasYConOpcionesDeRespuestaCompanion datosIniciales;

  late final controllersPreguntas = datosIniciales.preguntas
      .map((e) => CreadorPreguntaController(
            _repository,
            datosIniciales: e,
            parteDeCuadricula: true,
          ))
      .toList();

  late final preguntasControl = fb.array<Map<String, dynamic>>(
    controllersPreguntas.map((e) => e.control).toList(),

    /// Si es parte de cuadricula o numérica no tienen opciones de respuesta
    [Validators.minLength(1)],
  );

  /// Son las opciones de respuesta.
  /// Si el bloque es nuevo, son null y se pasa un FormArray vacío.
  /// Si es bloque copiado o viene de edición se pasa un FormArray con cada
  /// una de las opciones que ya existen para la pregutna
  @override
  late final controllersRespuestas = datosIniciales
      .cuadricula.opcionesDeRespuesta
      .map((e) => CreadorRespuestaController(e))
      .toList();

  @override
  late final respuestasControl = fb.array<Map<String, dynamic>>(
    controllersRespuestas.map((e) => e.control).toList(),

    /// Si es parte de cuadricula o numérica no tienen opciones de respuesta
    [Validators.minLength(1)],
  );
  final CamposGeneralesPreguntaController controllerCamposGenerales;
  late final camposGeneralesControl = controllerCamposGenerales.control;

  @override
  late final control = fb.group({
    'general': camposGeneralesControl,
    // de cuadricula
    'preguntas': preguntasControl,
    'respuestas': respuestasControl,
  });

  CreadorPreguntaCuadriculaController(
    this._repository, {
    this.datosIniciales =
        const CuadriculaConPreguntasYConOpcionesDeRespuestaCompanion.vacio(),
  }) : controllerCamposGenerales = CamposGeneralesPreguntaController(
          tituloInicial: datosIniciales.cuadricula.pregunta.titulo,
          descripcionInicial: datosIniciales.cuadricula.pregunta.descripcion,
          etiquetasIniciales: Value(datosIniciales.cuadricula.etiquetas),
          tipoInicial: datosIniciales.cuadricula.pregunta.tipoDePregunta,
          parteDeCuadricula: true,
        );

  @override
  CreadorPreguntaCuadriculaController copy() {
    final copied = toDB();

    return CreadorPreguntaCuadriculaController(
      _repository,
      datosIniciales: copied.copyWith(
        cuadricula: copied.cuadricula.copyWith(
          pregunta: copied.cuadricula.pregunta.copyWith(
            id: const Value.absent(),
            bloqueId: const Value.absent(),
          ),
          opcionesDeRespuesta: copied.cuadricula.opcionesDeRespuesta
              .map((o) => o.copyWith(
                    id: const Value.absent(),
                    preguntaId: const Value.absent(),
                  ))
              .toList(),
          etiquetas: copied.cuadricula.etiquetas
              .map((o) => o.copyWith(
                    id: const Value.absent(),
                  ))
              .toList(),
        ),
        preguntas: copied.preguntas
            .map((p) => p.copyWith(
                pregunta: p.pregunta.copyWith(
                  id: const Value.absent(),
                  bloqueId: const Value.absent(),
                ),
                opcionesDeRespuesta: p.opcionesDeRespuesta
                    .map((e) => e.copyWith(
                          id: const Value.absent(),
                          preguntaId: const Value.absent(),
                        ))
                    .toList()))
            .toList(),
      ),
    );
  }

  @override
  CuadriculaConPreguntasYConOpcionesDeRespuestaCompanion toDB() {
    final g = controllerCamposGenerales;
    return CuadriculaConPreguntasYConOpcionesDeRespuestaCompanion(
      datosIniciales.cuadricula.copyWith(
        pregunta: datosIniciales.cuadricula.pregunta.copyWith(
          titulo: Value(g.tituloControl.value!),
          descripcion: Value(
            g.descripcionControl.value!,
          ),
          tipoDePregunta: const Value(TipoDePregunta.cuadricula),
          tipoDeCuadricula: Value(
              g.tipoDePreguntaControl.value! == TipoDePregunta.seleccionUnica
                  ? TipoDeCuadricula.seleccionUnica
                  : TipoDeCuadricula.seleccionMultiple),
        ),
        opcionesDeRespuesta:
            controllersRespuestas.map((e) => e.toDB()).toList(),
      ),
      controllersPreguntas.map((e) {
        final e1 = e.toDB();
        return e1.copyWith(
          pregunta: e1.pregunta.copyWith(
            tipoDePregunta: Value(g.tipoDePreguntaControl.value!),
          ),
        );
      }).toList(),
    );
  }

  void agregarPregunta() {
    final nuevoController = CreadorPreguntaController(
      _repository,
      parteDeCuadricula: true,
    );
    controllersPreguntas.add(nuevoController);
    preguntasControl.add(nuevoController.control);
  }

  /// Elimina del control 'pregunta' una instancia
  void borrarPregunta(CreadorPreguntaController c) {
    controllersPreguntas.remove(c);
    preguntasControl.remove(c.control);
  }
}

class CreadorPreguntaNumericaController extends CreacionController {
  final CuestionariosRepository _repository;

  final PreguntaNumericaCompanion datosIniciales;

  late final criticidadControl = fb.control<double>(
      datosIniciales.pregunta.criticidad.valueOrDefault(0).toDouble());
  late final fotosGuiaControl = fb.control<List<AppImage>>(
    datosIniciales.pregunta.fotosGuia.valueOrDefault([]).toList(),
  );

  /// Rangos de criticidad
  late final controllersCriticidades = datosIniciales.criticidades
      .map((e) => CreadorCriticidadesNumericasController(e))
      .toList();
  late final criticidadesControl = fb.array<Map<String, dynamic>>(
    controllersCriticidades.map((e) => e.control).toList(),
  );
  final CamposGeneralesPreguntaController controllerCamposGenerales;
  late final camposGeneralesControl = controllerCamposGenerales.control;

  /// alias de [camposGeneralesControl], usar con sabiduría
  late final g = controllerCamposGenerales;

  @override
  late final control = fb.group({
    'general': camposGeneralesControl,
    // de numerica
    'criticidad': criticidadControl,
    'fotosGuia': fotosGuiaControl,
    'criticidadRespuesta': criticidadesControl,
  });

  CreadorPreguntaNumericaController(
    this._repository, {
    this.datosIniciales = const PreguntaNumericaCompanion.vacio(),
  }) : controllerCamposGenerales = CamposGeneralesPreguntaController(
          tituloInicial: datosIniciales.pregunta.titulo,
          descripcionInicial: datosIniciales.pregunta.descripcion,
          etiquetasIniciales: Value(datosIniciales.etiquetas),
          tipoInicial: datosIniciales.pregunta.tipoDePregunta,
          parteDeCuadricula: false,
        );

  /// Agrega control a 'criticidadRespuesta' para añadir un rango de criticidad a la pregunta numerica
  void agregarCriticidad() {
    final nuevoController = CreadorCriticidadesNumericasController();
    controllersCriticidades.add(nuevoController);
    criticidadesControl.add(nuevoController.control);
  }

  /// Elimina Control de 'criticidadRespuesta'
  void borrarCriticidad(CreacionController c) {
    controllersCriticidades.remove(c);
    criticidadesControl.remove(c.control);
  }

  @override
  CreadorPreguntaNumericaController copy() {
    final copied = toDB();

    return CreadorPreguntaNumericaController(
      _repository,
      datosIniciales: copied.copyWith(
        pregunta: copied.pregunta.copyWith(
          id: const Value.absent(),
          bloqueId: const Value.absent(),
        ),
        criticidades: copied.criticidades
            .map((o) => o.copyWith(
                  id: const Value.absent(),
                  preguntaId: const Value.absent(),
                ))
            .toList(),
        etiquetas: copied.etiquetas
            .map((o) => o.copyWith(
                  id: const Value.absent(),
                ))
            .toList(),
      ),
    );
  }

  /// En caso de que ya exista [datosIniciales], se actualiza con los nuevos
  /// valores introducidos en el formulario, (Como ya tiene id, se actualiza en la bd)
  /// Si no se "crea" uno con el método [toDataClass()]
  /// Este método es usado a la hora de guardar el cuestionario en la bd.
  @override
  PreguntaNumericaCompanion toDB() {
    return PreguntaNumericaCompanion(
      datosIniciales.pregunta.copyWith(
        titulo: Value(g.tituloControl.value!),
        descripcion: Value(g.descripcionControl.value!),
        criticidad: Value(criticidadControl.value!.round()),
        fotosGuia: Value(fotosGuiaControl.value!),
        tipoDePregunta: const Value(TipoDePregunta.numerica),
      ),
      controllersCriticidades.map((e) => e.toDB()).toList(),
      g.etiquetasControl.value!
          .map((e) => EtiquetasDePreguntaCompanion.insert(
              clave: e.split(":").first, valor: e.split(":").last))
          .toList(),
    );
  }
}

class CamposGeneralesPreguntaController {
  /// Diferencia las de selección y las que son de cuadricula
  final bool parteDeCuadricula;

  /// Controles del bloque del formulario
  final Value<String> tituloInicial;
  late final tituloControl = fb.control<String>(
    tituloInicial.valueOrDefault(""),
    [Validators.required],
  );

  final Value<String> descripcionInicial;
  late final descripcionControl =
      fb.control<String>(descripcionInicial.valueOrDefault(""));

  final Value<List<EtiquetasDePreguntaCompanion>> etiquetasIniciales;
  late final etiquetasControl = fb.control<Set<String>>(etiquetasIniciales
      .valueOrDefault([])
      .map((e) => '${e.clave.value}:${e.valor.value}')
      .toSet());

  /// Si es de cuadricula, no se debe requerir que elija el tipo e pregunta
  final Value<TipoDePregunta> tipoInicial;
  late final tipoDePreguntaControl = fb.control<TipoDePregunta>(
    tipoInicial.valueOrDefault(TipoDePregunta.seleccionUnica),
    [if (!parteDeCuadricula) Validators.required],
  );

  late final FormGroup control = fb.group({
    'titulo': tituloControl,
    'descripcion': descripcionControl,
    'etiquetas': etiquetasControl,
    'tipoDePregunta': tipoDePreguntaControl,
  });

  CamposGeneralesPreguntaController({
    required this.tituloInicial,
    required this.descripcionInicial,
    required this.etiquetasIniciales,
    required this.tipoInicial,
    this.parteDeCuadricula = false,
  });
}
