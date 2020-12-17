import 'package:flutter/foundation.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/injection.dart';
import 'package:inspecciones/mvvc/creacion_controls.dart';
import 'package:inspecciones/mvvc/creacion_validators.dart';
import 'package:reactive_forms/reactive_forms.dart';

//TODO: implementar la edicion de cuestionarios
//TODO: este viewmodel podria extender de FormGroup
class CreacionFormViewModel {
  final _db = getIt<Database>();

  final sistemas = ValueNotifier<List<Sistema>>([]);
  final tiposDeInspeccion = ValueNotifier<List<String>>([]);
  final modelos = ValueNotifier<List<String>>([]);
  final contratistas = ValueNotifier<List<Contratista>>([]);

  final tipoDeInspeccion =
      FormControl<String>(validators: [Validators.required]);

  final nuevoTipoDeinspeccion =
      FormControl<String>(value: ""); //validado desde el form

  final modelosSeleccionados = FormControl<List<String>>(
      value: [], validators: [Validators.minLength(1)]);

  final contratista =
      FormControl<Contratista>(validators: [Validators.required]);

  final periodicidad = FormControl<double>(validators: [Validators.required]);

  final bloques = FormArray([]);

  FormGroup form; //no cambiar please

  CreacionFormViewModel() {
    form = FormGroup({
      'tipoDeInspeccion': tipoDeInspeccion,
      'nuevoTipoDeInspeccion': nuevoTipoDeinspeccion,
      'modelos': modelosSeleccionados,
      'contratista': contratista,
      'periodicidad': periodicidad,
      'bloques': bloques,
    }, validators: [
      nuevoTipoDeInspeccion
    ], asyncValidators: [
      cuestionariosExistentes //FIXME: no recalcula cuando cambia el tipo de inspeccion
    ]);
    //agregar un titulo inicial
    bloques.add(CreadorTituloFormGroup());
    cargarDatos();
  }

  Future cargarDatos() async {
    tiposDeInspeccion.value = await _db.creacionDao.getTiposDeInspecciones();
    tiposDeInspeccion.value.add("otra");

    modelos.value = await _db.creacionDao.getModelos();
    contratistas.value = await _db.creacionDao.getContratistas();
    sistemas.value = await _db.creacionDao.getSistemas();
  }

  /// Metodo que funciona sorprendentemente bien con los nulos y los casos extremos
  void agregarBloqueDespuesDe(
      {AbstractControl bloque, AbstractControl despuesDe}) {
    bloques.insert(bloques.controls.indexOf(despuesDe) + 1, bloque);
  }

  void borrarBloque(AbstractControl e) {
    //TODO hacerle dispose si se requiere
    try {
      bloques.remove(e);
      // ignore: empty_catches
    } on FormControlNotFoundException {}
  }

  Future enviar() async {
    form.markAllAsTouched();
    await _db.creacionDao.crearCuestionario(form.controls);
  }

  /// Cierra todos los streams para evitar fugas de memoria, se suele llamar desde el provider
  void dispose() {
    tiposDeInspeccion.dispose();
    modelos.dispose();
    contratistas.dispose();
    sistemas.dispose();
    form.dispose();
  }
}
