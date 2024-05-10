import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InspeccionesDbViewerPage extends ConsumerWidget {
  const InspeccionesDbViewerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    //TODO: revisar
    return const Text(
        'Hola'); /* MoorDbViewer(ref.read(driftDatabaseProvider)); */
  }
}
