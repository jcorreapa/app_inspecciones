//Custom Validators
import 'package:reactive_forms/reactive_forms.dart';

import 'creacion_form_controller.dart';

//FIXME: no recalcula cuando cambia el tipo de inspeccion
/// Cuando se crea un cuestionario
/// Valida que no exista un [tipoDeInspeccion] aplicado a los mismos [modelos].
/// TODO: analizar bien esto
///! Sera que el validator va en el modelosControl??
/*AsyncValidatorFunction cuestionariosExistentes(
  int? cuestionarioId,
  FormControl<String?> tipoDeInspeccionControl,
  FormControl<List<String>> modelosControl,
  CuestionariosRepository repository,
) =>
    (
      AbstractControl<dynamic> control,
    ) async {
      final ti = tipoDeInspeccionControl.value;
      final mod = modelosControl.value;

      if (ti == null || mod == null || cuestionarioId == null) return null;

      /// Se consulta si ya existe algun cuestionario aplicado a los mismos modelos.
      final cuestionariosExistentes =
          await repository.getCuestionarios(ti, mod);

      if (cuestionariosExistentes.isNotEmpty) {
        try {
          cuestionariosExistentes.firstWhere((cu) => cu.id != cuestionarioId);
          modelosControl.setErrors({
            'yaExiste': true /*cuestionariosExistentes.first.modelo*/
          });
          modelosControl.markAsTouched();
        } on StateError {
          modelosControl.removeError('yaExiste');
        }
      } else {
        modelosControl.removeError('yaExiste');
      }
      return null;
    };*/

/// Marca como requerido el textField de 'nuevoTipoDeInspeccion',
/// en caso de que se haya seleccionado 'Otra' como tipo de inspeccion.

class NuevoTipoDeInspeccionValidator extends Validator<dynamic> {
  final FormControl<String?> tipoDeInspeccionControl;
  final FormControl<String?> nuevoTipoDeInspeccionControl;

  NuevoTipoDeInspeccionValidator(
    this.tipoDeInspeccionControl,
    this.nuevoTipoDeInspeccionControl,
  );

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final ti = tipoDeInspeccionControl.value;
    final nti = nuevoTipoDeInspeccionControl.value;
    if (ti == null || nti == null) return null;

    final error = {ValidationMessage.required: true};

    if (ti == CreacionFormController.otroTipoDeInspeccion &&
        nti.trim().isEmpty) {
      nuevoTipoDeInspeccionControl.setErrors(error);
      //nuevoTipoDeinspeccion.markAsTouched();
    } else {
      nuevoTipoDeInspeccionControl.removeError(ValidationMessage.required);
    }
    return null;
  }
}

/// Validación que verifica que el valor del textfield para 'minimo' sea menor que el valor introducido en el textfield 'maximo'.
/// En las preguntas numéricas

class VerificarRango extends Validator<dynamic> {
  final FormControl<double> controlMinimo;
  final FormControl<double> controlMaximo;

  VerificarRango(this.controlMinimo, this.controlMaximo);

  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    if (controlMinimo.value == null || controlMaximo.value == null) {
      controlMaximo.removeError('verificarRango');
      return null;
    }
    if (controlMinimo.value! > controlMaximo.value!) {
      controlMaximo.setErrors({'verificarRango': true});
    } else {
      controlMaximo.removeError('verificarRango');
    }

    return null;
  }
}
