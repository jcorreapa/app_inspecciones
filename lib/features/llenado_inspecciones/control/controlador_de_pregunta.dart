import 'package:inspecciones/core/entities/app_image.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../domain/bloques/pregunta.dart';
import '../domain/metarespuesta.dart';
import 'visitors/controlador_de_pregunta_visitor.dart';

abstract class ControladorDePregunta<T extends Pregunta,
    R extends AbstractControl> {
  final T pregunta;
  late DateTime? momentoRespuesta =
      pregunta.respuesta?.metaRespuesta.momentoRespuesta;
  late final MetaRespuesta respuesta =
      pregunta.respuesta?.metaRespuesta ?? MetaRespuesta.vacia();

  // se asigna 1 por defecto porque el widget no acepta null, por lo tanto se
  //solo las opciones de respuesta que acepten criticidad del inspector deben
  // guardar este valor, de lo contrario se guarda null
  late final criticidadDelInspectorControl =
      fb.control(respuesta.criticidadDelInspector ?? 1);

  late final observacionControl = fb.control(respuesta.observaciones);
  late final reparadoControl = fb.control(respuesta.reparada);

  late final observacionReparacionControl = fb.control(
    respuesta.observacionesReparacion,
  );
  late final fotosBaseControl = fb.control<List<AppImage>>(respuesta.fotosBase);
  late final fotosReparacionControl =
      fb.control<List<AppImage>>(respuesta.fotosReparacion);

  abstract final R respuestaEspecificaControl;
  late final metaRespuestaControl = fb.group({
    "criticidadDelInspector": criticidadDelInspectorControl,
    "observacion": observacionControl,
    "observacionReparacion": observacionReparacionControl,
    "reparado": reparadoControl,
    "fotosBase": fotosBaseControl,
    "fotosReparacion": fotosReparacionControl,
  }, [
    // Aunque un control sea inválido, el grupo es válido. Se valida el grupo entero.
    ReparadoValidator().validate
  ]);

  /// el control de reactive forms que debe contener directa o indirectamente
  /// todos los controles asociados a este [ControladorDePregunta], si algun
  /// control no se asocia, entonces no se validará ni se desactivará cuando
  /// sea necesario
  final FormGroup control = FormGroup({});

  ControladorDePregunta(this.pregunta) {
    // el addAll es necesario para que el grupo sea invalido cuando uno de los controles
    // sean invalidos,
    // TODO: investigar por que ocurre esto
    control.addAll({
      'metaRespuesta': metaRespuestaControl,
      "respuestaEspecifica": respuestaEspecificaControl,
    });
    respuestaEspecificaControl.valueChanges.listen((_) {
      momentoRespuesta = DateTime.now();
    }); //guarda el momento de la ultima edicion
  }

  bool esValido() => control.valid;

  bool get requiereCriticidadDelInspector;

  /// las preguntas de seleccion deben sobreescribir este método para agregarle
  /// la criticidad del inspector
  MetaRespuesta guardarMetaRespuesta() => MetaRespuesta(
        observaciones: observacionControl.value!,
        fotosBase: fotosBaseControl.value!,
        reparada: reparadoControl.value!,
        observacionesReparacion: observacionReparacionControl.value!,
        fotosReparacion: fotosReparacionControl.value!,
        momentoRespuesta: momentoRespuesta,
        criticidadDelInspector: requiereCriticidadDelInspector
            ? criticidadDelInspectorControl.value
            : null,
      );

  /// solo se puede usar para leer el calculo, para componentes de la ui que deben
  /// reaccionar a cambios de este calculo se debe usar [criticidadCalculadaProvider]
  int get criticidadCalculada => (criticidadPregunta *
          // si no hay respuesta la criticidad es 0
          (criticidadRespuesta ?? 0) *
          // si no aplica, no modifica el calculo
          (requiereCriticidadDelInspector //TODO: escucharlo en el provider
              ? _calificacionToPorcentaje(criticidadDelInspectorControl.value!)
              : 1) *
          // si esta reparada la criticidad es 0
          (reparadoControl.value! ? 0 : 1))
      .round();

  int get criticidadPregunta => pregunta.criticidad;

  /// debe basarse unicamente en informacion obtenida de respuestaEspecificaControl
  /// para que [criticidadCalculadaProvider] funcione bien
  int? get criticidadRespuesta;

  V accept<V>(ControladorDePreguntaVisitor<V> visitor);

  /// verificar que este factor solo pueda reducir la criticidad
  static double _calificacionToPorcentaje(int calificacion) {
    switch (calificacion.round()) {
      case 1:
        return 0.55;

      case 2:
        return 0.70;

      case 3:
        return 0.85;

      case 4:
        return 1;

      default:
        throw Exception(
            "el valor de calificacion inválido, solo se permite de 1 a 4");
    }
  }
}

class ReparadoValidator extends Validator<dynamic> {
  @override
  Map<String, dynamic>? validate(AbstractControl<dynamic> control) {
    final metaRespuestaControl = control as FormGroup;
    final reparado =
        metaRespuestaControl.control('reparado') as FormControl<bool>;
    final observacion = metaRespuestaControl.control('observacionReparacion')
        as FormControl<String>;
    final fotosReparacion = metaRespuestaControl.control('fotosReparacion')
        as FormControl<List<AppImage>>;
    final error = {ValidationMessage.required: true};
    if (reparado.value != null && reparado.value!) {
      if (observacion.value!.trim().isEmpty) {
        observacion.setErrors(error);
      }
      if (fotosReparacion.value!.isEmpty) {
        fotosReparacion.setErrors(error);
      }
    } else {
      observacion.removeError(ValidationMessage.required);
      fotosReparacion.removeError(ValidationMessage.required);
    }
    return null;
  }
}
