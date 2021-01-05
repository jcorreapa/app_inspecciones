import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:inspecciones/core/enums.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/injection.dart';
import 'package:kt_dart/kt.dart';

import 'package:reactive_forms/reactive_forms.dart';

class CreadorTituloFormGroup extends FormGroup implements Copiable {
  CreadorTituloFormGroup([Titulo d])
      : super({
          'titulo': fb.control<String>(d?.titulo ?? "", [Validators.required]),
          'descripcion': fb.control<String>(d?.descripcion ?? "")
        });

  @override
  Future<CreadorTituloFormGroup> copiar() async {
    return CreadorTituloFormGroup(toDataclass());
  }

  Titulo toDataclass() => Titulo(
        id: null,
        fotos: null,
        bloqueId: null,
        titulo: value["titulo"] as String,
        descripcion: value["descripcion"] as String,
      );
}

class CreadorPreguntaFormGroup extends FormGroup
    implements ConRespuestas, Copiable {
  final ValueNotifier<List<SubSistema>> subSistemas;

  factory CreadorPreguntaFormGroup({
    PreguntaConOpcionesDeRespuesta defaultValue,
    bool parteDeCuadricula = false,
    bool esNumerica = false,
  }) {
    final d = defaultValue;
    final sistema = fb.control<Sistema>(null, [Validators.required]);
    final subSistemas = ValueNotifier<List<SubSistema>>([]);

    sistema.valueChanges.asBroadcastStream().listen((sistema) async {
      subSistemas.value =
          await getIt<Database>().creacionDao.getSubSistemas(sistema);
    });

    final Map<String, AbstractControl<dynamic>> controles = {
      'titulo':
          fb.control<String>(d?.pregunta?.titulo ?? "", [Validators.required]),
      'descripcion': fb.control<String>(d?.pregunta?.descripcion ?? ""),
      'sistema': sistema,
      'subSistema': fb.control<SubSistema>(null, [Validators.required]),
      'posicion': fb.control<String>(d?.pregunta?.posicion ?? "no aplica"),
      'criticidad':
          fb.control<double>(d?.pregunta?.criticidad?.toDouble() ?? 0),
      'fotosGuia': fb.array<File>(
          d?.pregunta?.fotosGuia?.iter?.map((e) => File(e))?.toList() ?? []),
      'tipoDePregunta': fb.control<TipoDePregunta>(d?.pregunta?.tipo, [
        if (!parteDeCuadricula) Validators.required
      ]), //em realidad para las cuadriculas de debe manejar distinto pero se reescribira mas adelante
      'respuestas': fb.array<Map<String, dynamic>>(
        d?.opcionesDeRespuesta
                ?.map((e) => CreadorRespuestaFormGroup(e))
                ?.toList() ??
            [],
        [if (!parteDeCuadricula || esNumerica == false) Validators.minLength(1)],
      ),
    };

    return CreadorPreguntaFormGroup._(controles, subSistemas, d: d);
  }

  //constructor que le envia los controles a la clase padre
  CreadorPreguntaFormGroup._(
      Map<String, AbstractControl<dynamic>> controles, this.subSistemas,
      {PreguntaConOpcionesDeRespuesta d})
      : super(controles) {
    instanciarControls(d);
    // Machetazo que puede dar resultados inesperados si se utiliza el
    // constructor en codigo sincrono ya que no se está esperando a que termine esta funcion asincrona
  }

  /// debido a que las instancias de sistema y subsistema se deben obtener desde la bd,
  /// se debe usar esta factory que los busca en la bd, de lo contrario quedan null
  /*static Future<CreadorPreguntaFormGroup> crearAsync(
      [PreguntaConOpcionesDeRespuesta d]) async {
    final instancia = CreadorPreguntaFormGroup(defaultValue: d);

    // Do initialization that requires async
    

    // Return the fully initialized object
    return instancia;
  }*/
  Future<void> instanciarControls(PreguntaConOpcionesDeRespuesta d) async {
    controls['sistema'].value =
        await getIt<Database>().getSistemaPorId(d?.pregunta?.sistemaId);
    controls['subSistema'].value =
        await getIt<Database>().getSubSistemaPorId(d?.pregunta?.subSistemaId);
  }

  @override
  Future<CreadorPreguntaFormGroup> copiar() async {
    return CreadorPreguntaFormGroup(defaultValue: toDataclass());
  }

  PreguntaConOpcionesDeRespuesta toDataclass() =>
      PreguntaConOpcionesDeRespuesta(
        Pregunta(
          id: null,
          bloqueId: null,
          titulo: value['titulo'] as String,
          descripcion: value['descripcion'] as String,
          sistemaId: (value['sistema'] as Sistema)?.id,
          subSistemaId: (value['subSistema'] as SubSistema)?.id,
          posicion: value['posicion'] as String,
          criticidad: (value['criticidad'] as double).round(),
          fotosGuia: (control('fotosGuia') as FormArray<File>)
              .controls
              .map((e) => e.value.path)
              .toImmutableList(),
          tipo: value['tipoDePregunta'] as TipoDePregunta,
        ),
        (control('respuestas') as FormArray).controls.map((e) {
          final formGroup = e as CreadorRespuestaFormGroup;
          return formGroup.toDataClass();
        }).toList(),
      );

  @override
  void agregarRespuesta() =>
      (control('respuestas') as FormArray).add(CreadorRespuestaFormGroup());

  @override
  void borrarRespuesta(AbstractControl e) {
    try {
      (control('respuestas') as FormArray).remove(e);
      // ignore: empty_catches
    } on FormControlNotFoundException {}
    return;
  }

  @override
  void dispose() {
    super.dispose();
    subSistemas.dispose();
  }
}

class CreadorRespuestaFormGroup extends FormGroup {
  CreadorRespuestaFormGroup([OpcionDeRespuesta d])
      : super({
          'texto': fb.control<String>(d?.texto ?? "", [Validators.required]),
          'criticidad': fb.control<double>(d?.criticidad?.toDouble() ?? 0)
        });

  OpcionDeRespuesta toDataClass() => OpcionDeRespuesta(
        id: null,
        texto: value['texto'] as String,
        criticidad: (value['criticidad'] as double).round(),
      );
}


class CreadorPreguntaCuadriculaFormGroup extends FormGroup
    implements ConRespuestas, Copiable {
  final ValueNotifier<List<SubSistema>> subSistemas;

  factory CreadorPreguntaCuadriculaFormGroup(
      {CuadriculaConPreguntasYConOpcionesDeRespuesta defaultValue}) {
    final d = defaultValue;
    final sistema = fb.control<Sistema>(null, [Validators.required]);
    final subSistemas = ValueNotifier<List<SubSistema>>([]);

    sistema.valueChanges.asBroadcastStream().listen((sistema) async {
      subSistemas.value =
          await getIt<Database>().creacionDao.getSubSistemas(sistema);
    });

    final Map<String, AbstractControl<dynamic>> controles = {
      'titulo': fb.control<String>(d?.cuadricula?.titulo ?? ""),
      'descripcion': fb.control<String>(d?.cuadricula?.descripcion ?? ""),
      'sistema': sistema,
      'subSistema': fb.control<SubSistema>(null, [Validators.required]),
      'posicion': fb.control<String>("no aplica"),
      'preguntas': fb.array<Map<String, dynamic>>(
        d?.preguntas
                ?.map((e) => CreadorPreguntaFormGroup(
                    defaultValue: e, parteDeCuadricula: true))
                ?.toList() ??
            [],
        [Validators.minLength(1)],
      ),
      'respuestas': fb.array<Map<String, dynamic>>(
        d?.opcionesDeRespuesta
                ?.map((e) => CreadorRespuestaFormGroup(e))
                ?.toList() ??
            [],
        [Validators.minLength(1)],
      ),
    };

    return CreadorPreguntaCuadriculaFormGroup._(controles, subSistemas);
  }
  CreadorPreguntaCuadriculaFormGroup._(
    Map<String, AbstractControl<dynamic>> controles,
    this.subSistemas,
  ) : super(controles);

  /// Se le agrega el sistema y subsistema por defecto de la cuadricula,
  /// similar a lo que realiza la factory crearAsync pero sin otros valores por defecto
  Future<void> agregarPregunta() async {
    final instancia = CreadorPreguntaFormGroup(parteDeCuadricula: true);
    await Future.delayed(const Duration(
        seconds:
            1)); //machete para poder asignar el sistema sin que el constructor le asigne null despues
    instancia.controls['sistema'].value = value['sistema'] as Sistema;
    instancia.controls['subSistema'].value = value['subSistema'] as SubSistema;
    (control('preguntas') as FormArray).add(instancia);
  }

  void borrarPregunta(AbstractControl e) {
    try {
      (control('preguntas') as FormArray).remove(e);
      // ignore: empty_catches
    } on FormControlNotFoundException {}
  }

  @override
  void agregarRespuesta() {
    (control('respuestas') as FormArray).add(CreadorRespuestaFormGroup());
  }

  @override
  void borrarRespuesta(AbstractControl e) {
    try {
      (control('respuestas') as FormArray).remove(e);
      // ignore: empty_catches
    } on FormControlNotFoundException {}
  }

  @override
  void dispose() {
    super.dispose();
    subSistemas.dispose();
  }

  @override
  Future<CreadorPreguntaCuadriculaFormGroup> copiar() async {
    //instanciar los sistemas y subsitemas de las preguntas

    return CreadorPreguntaCuadriculaFormGroup(defaultValue: toDataclass());
  }

  CuadriculaConPreguntasYConOpcionesDeRespuesta toDataclass() =>
      CuadriculaConPreguntasYConOpcionesDeRespuesta(
        CuadriculaDePreguntas(
          id: null,
          bloqueId: null,
          titulo: value['titulo'] as String,
          descripcion: value['descripcion'] as String,
        ),
        (controls['preguntas'] as FormArray).controls.map((e) {
          final formGroup = e as CreadorPreguntaFormGroup;
          return formGroup.toDataclass();
        }).toList(),
        (control('respuestas') as FormArray).controls.map((e) {
          final formGroup = e as CreadorRespuestaFormGroup;
          return formGroup.toDataClass();
        }).toList(),
        /*List<PreguntaConOpcionesDeRespuesta>
        List<OpcionDeRespuesta>*/
      );
}

class CreadorPreguntaNumericaFormGroup extends FormGroup implements Copiable {
  
final ValueNotifier<List<SubSistema>> subSistemas;
  factory CreadorPreguntaNumericaFormGroup({
    Pregunta defaultValue,
  }) {
    final d = defaultValue;
    final sistema = fb.control<Sistema>(null, [Validators.required]);
    final subSistemas = ValueNotifier<List<SubSistema>>([]);

    sistema.valueChanges.asBroadcastStream().listen((sistema) async {
      subSistemas.value =
          await getIt<Database>().creacionDao.getSubSistemas(sistema);
    });

    final Map<String, AbstractControl<dynamic>> controles = {
      'titulo':
          fb.control<String>(d?.titulo ?? "", [Validators.required]),
      'descripcion': fb.control<String>(d?.descripcion ?? ""),
      'sistema': sistema,
      'subSistema': fb.control<SubSistema>(null, [Validators.required]),
      'posicion': fb.control<String>(d?.posicion ?? "no aplica"),
      'criticidad':
          fb.control<double>(d?.criticidad?.toDouble() ?? 0),
      'fotosGuia': fb.array<File>(
          d?.fotosGuia?.iter?.map((e) => File(e))?.toList() ?? []),
    
      //em realidad para las cuadriculas de debe manejar distinto pero se reescribira mas adelante
    };

    return CreadorPreguntaNumericaFormGroup._(controles, subSistemas, d: d);

  }
  CreadorPreguntaNumericaFormGroup._(
      Map<String, AbstractControl<dynamic>> controles, this.subSistemas,
      {Pregunta d})
      : super(controles) {
    instanciarControls(d);
    // Machetazo que puede dar resultados inesperados si se utiliza el
    // constructor en codigo sincrono ya que no se está esperando a que termine esta funcion asincrona
  }


  Future<void> instanciarControls(Pregunta d) async {
    controls['sistema'].value =
        await getIt<Database>().getSistemaPorId(d?.sistemaId);
    controls['subSistema'].value =
        await getIt<Database>().getSubSistemaPorId(d?.subSistemaId);
  }

  @override
  Future<CreadorPreguntaNumericaFormGroup> copiar() async {
    return CreadorPreguntaNumericaFormGroup(defaultValue: toDataclass());

  }
  Pregunta toDataclass() =>
        Pregunta(
          id: null,
          bloqueId: null,
          titulo: value['titulo'] as String,
          descripcion: value['descripcion'] as String,
          sistemaId: (value['sistema'] as Sistema)?.id,
          subSistemaId: (value['subSistema'] as SubSistema)?.id,
          posicion: value['posicion'] as String,
          criticidad: (value['criticidad'] as double).round(),
          fotosGuia: (control('fotosGuia') as FormArray<File>)
              .controls
              .map((e) => e.value.path)
              .toImmutableList(),
          tipo: TipoDePregunta.numerica,
        );
    
}
/*
class CreadorSubPreguntaCuadriculaFormGroup extends FormGroup {
  CreadorSubPreguntaCuadriculaFormGroup()
      : super({
          //! En la bd se agrega el sistema, subsistema, posicion, tipodepregunta correspondiente para no crear mas controles aqui
          'titulo': fb.control<String>("", [Validators.required]),
          'descripcion': fb.control<String>(""),
          'criticidad': fb.control<double>(0),
        });
}
*/
abstract class ConRespuestas {
  void agregarRespuesta();
  void borrarRespuesta(AbstractControl e);
}

abstract class Copiable {
  Future<AbstractControl> copiar();
}
