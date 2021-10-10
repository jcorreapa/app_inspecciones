import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inspecciones/presentation/widgets/user_drawer.dart';

import 'providers.dart';
import 'sincronizacion_controller.dart';

/// Pantalla que muestra el progreso de a descarga de datos de gomac
class SincronizacionPage extends ConsumerWidget {
  const SincronizacionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final sincronizacionNotifier = ref.watch(sincronizacionProvider.notifier);
    final sincronizacionState = ref.watch(sincronizacionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        actions: const [
          /// Inicio de descarga de datos
          BotonDescarga(),
        ],
      ),
      drawer: const UserDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              color: Theme.of(context).primaryColorLight,
              child: ListTile(
                leading: const Icon(
                  Icons.auto_delete,
                  color: Colors.red,
                ),
                subtitle: Text(
                  'Al sincronizar con GOMAC, es posible que se pierdan algunos borradores. Envíe lo que tenga pendiente antes de iniciar la descarga',
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            const Divider(),
            /*Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: LinearProgressIndicator(
                value: state.task != null ? state.task.progress / 100 : 0,
              ),
            ),
            const Divider(),*/

            /// División de los pasos de la sincronización
            Card(
                margin: const EdgeInsets.only(left: 50, right: 50),
                child: Stepper(
                  onStepTapped: (index) {
                    sincronizacionNotifier.selectPaso(index);
                  },
                  currentStep: sincronizacionState.paso,
                  steps: [
                    for (final step in sincronizacionNotifier.steps)
                      Step(
                        // aqui tocó usar el state de el StateNotifier de cada control
                        // en teoria no se puede pero no encontré otra manera
                        // ignore: invalid_use_of_protected_member
                        state: step.state.map(
                            initial: (_) => StepState.indexed,
                            inProgress: (_) => StepState.editing,
                            success: (_) => StepState.complete,
                            failure: (_) => StepState.error),
                        title: Text(step.titulo,
                            style: Theme.of(context).textTheme.subtitle2),
                        content: StreamBuilder<SincronizacionStepState>(
                          stream: step.stream,
                          builder: (context, state) => Text(
                              state.data?.log ?? "",
                              style: Theme.of(context).textTheme.subtitle2),
                        ),
                      ),
                  ],
                )),

            const SizedBox(
              height: 10,
            ),

            /// Ultima sincronización.
            Consumer(builder: (_, ref, __) {
              final ultimaSincronizacion =
                  ref.watch(momentoDeSincronizacionProvider);
              return Text("Ultima sincronizacion: " +
                  (ultimaSincronizacion?.toIso8601String() ??
                      "Nunca se ha sincronizado"));
            })
          ],
        ),
      ),
    );
  }
}

/// Inicio de descarga de datos mediante el [FlutterDownloader]
class BotonDescarga extends ConsumerWidget {
  const BotonDescarga({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final sincronizacionNotifier = ref.watch(sincronizacionProvider.notifier);

    return OutlinedButton.icon(
      onPressed: sincronizacionNotifier.iniciarProceso,
      icon: const Icon(Icons.play_arrow, color: Colors.white),
      label: const Text(
        "Iniciar descarga",
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}