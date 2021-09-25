import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../control/controlador_de_pregunta.dart';
import '../../control/controlador_llenado_inspeccion.dart';
import '../../control/providers.dart';
import '../../domain/inspeccion.dart';
import 'widget_criticidad_inspector.dart';

class WidgetRespuesta extends StatelessWidget {
  final ControladorDePregunta control;

  const WidgetRespuesta(
    this.control, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (control.pregunta.calificable)
          WidgetCriticidadInspector(control.criticidadInspectorControl),
        ReactiveTextField(
          formControl: control.observacionControl,
          decoration: const InputDecoration(
            labelText: 'observaciones',
            prefixIcon: Icon(Icons.remove_red_eye),
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
        ),
        Consumer(builder: (context, ref, _) {
          final estadoDeInspeccion =
              ref.watch(estadoDeInspeccionProvider).state;
          // si la criticidad de la respuesta no esta definida entonces por
          // defecto decimos que es 1
          final criticidadRespuesta =
              ref.watch(criticidadRespuestaProvider(control)) ?? 1;
          final mostrarReparacion = criticidadRespuesta > 0 &&
              estadoDeInspeccion != EstadoDeInspeccion.enBorrador;

          final reparado = ref.watch(reparadoProvider(control.reparadoControl));

          if (!mostrarReparacion) {
            return const SizedBox.shrink();
          } else {
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  horizontalTitleGap: 0,
                  leading:
                      ReactiveCheckbox(formControl: control.reparadoControl),
                  title: const Text("reparado"),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    height: reparado ? null : 0,
                    child: reparado
                        ? ReactiveTextField(
                            formControl: control.observacionReparacionControl,
                            decoration: const InputDecoration(
                              labelText: 'observaciones reparacion',
                              prefixIcon: Icon(Icons.remove_red_eye),
                            ),
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          }
        })
      ],
    );
  }
}