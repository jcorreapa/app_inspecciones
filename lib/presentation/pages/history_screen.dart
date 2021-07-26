import 'package:auto_route/auto_route.dart';
import 'package:auto_route/src/route_def.dart';
import 'package:auto_route/src/route_matcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inspecciones/application/auth/auth_bloc.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/infrastructure/repositories/inspecciones_repository.dart';
import 'package:inspecciones/injection.dart';
import 'package:inspecciones/router.gr.dart';
import 'package:provider/provider.dart';

class HistoryInspeccionesPage extends StatelessWidget
    implements AutoRouteWrapper {
  Widget wrappedRoute(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    return MultiProvider(
      providers: [
        RepositoryProvider(
            create: (ctx) =>
                getIt<InspeccionesRepository>(
                    param1: authBloc.state.maybeWhen(
                        authenticated: (u, s) => u.token,
                        orElse: () =>
                        throw Exception(
                            "Error inesperado: usuario no encontrado")))),
        RepositoryProvider(create: (_) => getIt<Database>()),
        StreamProvider(
            create: (_) =>
                getIt<Database>().borradoresDao.borradoresHistorial()),
      ],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          _clearHistory(),
        ],
      ),
      body: Consumer<List<Borrador>>(
          builder: (context, borradoresHistorial, child) {
            final textTheme = Theme
                .of(context)
                .textTheme;
            if (borradoresHistorial == null) {
              return const Text("Hay un null");
            }
            if (borradoresHistorial.isEmpty) {
              return Center(
                child: Text(
                  "No tiene inspecciones enviadas",
                  style: textTheme.headline5,
                ),
              );
            }
            return ListView.separated(
              separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
              itemCount: borradoresHistorial.length,
              itemBuilder: (context, index) {
                final borrador = borradoresHistorial[index];
                final _dateSend = borrador.inspeccion.momentoEnvio;
                return ListTile(
                  tileColor: Theme
                      .of(context)
                      .cardColor,
                  title: Text(
                    "${borrador.inspeccion.activoId} - ${borrador.activo
                        .modelo}",
                    style: textTheme.headline6,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        _dateSend == null
                            ? "Fecha de envío: "
                            : "Fecha de envío: ${_dateSend.day}/${_dateSend
                            .month}/${_dateSend.year} ${_dateSend
                            .hour}:${_dateSend.minute}",
                        style: textTheme.subtitle1,
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteBorrador(context, borrador),
                  ),
                );;
              },
            );
          }),
    );
  }

  Widget _listTile(BuildContext context, Borrador borrador,
      TextTheme textTheme) {
    final _dateSend = borrador.inspeccion.momentoEnvio;
    return ListTile(
      tileColor: Theme
          .of(context)
          .cardColor,
      title: Text(
        "${borrador.inspeccion.activoId} - ${borrador.activo.modelo}",
        style: textTheme.headline6,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 5,
          ),
          Text(
            _dateSend == null
                ? "Fecha de envío: "
                : "Fecha de envío: ${_dateSend.day}/${_dateSend
                .month}/${_dateSend.year} ${_dateSend.hour}:${_dateSend
                .minute}",
            style: textTheme.subtitle1,
          )
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () => _deleteBorrador(context, borrador),
      ),
    );
  }

  void _deleteBorrador(BuildContext context, Borrador borrador) {
    final _noButton = FlatButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("No"));
    final _yesButton = FlatButton(
        onPressed: () async {
          Navigator.of(context).pop();
          await RepositoryProvider
              .of<Database>(context)
              .borradoresDao
              .eliminarBorrador(borrador);
          Scaffold.of(context).showSnackBar(const SnackBar(
            content: Text("Borrador eliminado"),
            duration: Duration(seconds: 3),
          ));
        },
        child: const Text("Si")
    );
    final alert = AlertDialog(
        title: const Text("Eliminar historial"),
        content: const Text(
            "¿Esta seguro de eliminar ésta inspección del historial?"),
        actions: [
        _yesButton,
        _noButton,
        ]
    );
    showDialog(context: context,builder: (BuildContext context) => alert);
  }

  Widget _clearHistory() {
    return FlatButton(
        onPressed: () => {},
        child: const Text(
          "Limpiar historial",
          style: TextStyle(color: Colors.white, fontSize: 15),
        ));
  }
}
