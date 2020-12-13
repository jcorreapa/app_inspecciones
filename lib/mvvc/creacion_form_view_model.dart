import 'package:flutter/foundation.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/injection.dart';
import 'package:inspecciones/mvvc/creacion_controls.dart';
import 'package:reactive_forms/reactive_forms.dart';

part 'creacion_datos_test.dart';

//TODO: agregar todas las validaciones necesarias
//TODO: implementar la edicion de cuestionarios

Future<Map<String, dynamic>> _cuestionariosExistentes(
    AbstractControl<dynamic> control) async {
  final form = control as FormGroup;

  final tipoDeInspeccion = form.control('tipoDeInspeccion');
  final modelos = form.control('modelos');

  final cuestionariosExistentes = await getIt<Database>()
      .getCuestionarios(tipoDeInspeccion.value, modelos.value);
  if (cuestionariosExistentes.length > 0) {
    tipoDeInspeccion.setErrors({'yaExiste': true});
    tipoDeInspeccion.markAsTouched();
    /*return "Ya hay un cuestionario para esta inspeccion y \n el modelo " +
        cuestionariosExistentes.first.modelo;*/
  } else {
    tipoDeInspeccion.removeError('yaExiste');
  }
  return null;
}

class CreacionFormViewModel {
  final _db = getIt<Database>();

  ValueNotifier<List<Sistema>> sistemas = ValueNotifier([]);

  ValueNotifier<List<String>> tiposDeInspeccion = ValueNotifier([]);
  final tipoDeInspeccion = FormControl<String>();

  final nuevoTipoDeinspeccion = FormControl<String>();

  ValueNotifier<List<String>> modelos = ValueNotifier([]);

  final modelosSeleccionados = FormControl<List<String>>(value: []);

  ValueNotifier<List<Contratista>> contratistas = ValueNotifier([]);
  final contratista = FormControl<Contratista>();

  final periodicidad = FormControl<double>();

  final bloques = FormArray([]);

  final form = FormGroup({}, asyncValidators: [_cuestionariosExistentes]);

  CreacionFormViewModel() {
    form.addAll({
      'tipoDeInspeccion': tipoDeInspeccion,
      'nuevoTipoDeInspeccion': nuevoTipoDeinspeccion,
      'modelos': modelosSeleccionados,
      'contratista': contratista,
      'periodicidad': periodicidad,
      'bloques': bloques,
    });
    //agregar un titulo inicial
    bloques.add(CreadorTituloFormGroup());
    cargarDatos();
  }

  Future cargarDatos() async {
    tiposDeInspeccion.value = await _db.getTiposDeInspecciones();
    tiposDeInspeccion.value.add("otra");

    modelos.value = await _db.getModelos();
    contratistas.value = await _db.getContratistas();
    sistemas.value = await _db.getSistemas();
  }

  /// Metodo que funciona sorprendentemente bien con los nulos y los casos extremos
  agregarBloqueDespuesDe({AbstractControl bloque, AbstractControl despuesDe}) {
    bloques.insert(bloques.controls.indexOf(despuesDe) + 1, bloque);
  }

  borrarBloque(AbstractControl e) {
    //TODO hacerle dispose si se requiere
    try {
      bloques.remove(e);
    } on FormControlNotFoundException {
      print("que pendejo");
    }
  }

  enviar() async {
    print(form.controls);
    await _db.crearCuestionarioFromReactiveForm(form.controls);
  }

  /// Cierra todos los streams para evitar fugas de memoria, se suele llamar desde el provider
  dispose() {
    tiposDeInspeccion.dispose();
    modelos.dispose();
    contratistas.dispose();
    sistemas.dispose();
    form.dispose();
  }
}
