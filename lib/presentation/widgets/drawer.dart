import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:inspecciones/application/auth/auth_bloc.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/injection.dart';
import 'package:moor_db_viewer/moor_db_viewer.dart';
import 'package:provider/provider.dart';
import 'package:inspecciones/router.gr.dart';

class UserDrawer extends StatelessWidget {
  //TODO: si se genera este mismo drawer en varias paginas se puede crear un stack indeseado, una solucion seria que la instancia del drawer fuera unica en toda la app
  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);

    final authState = authBloc.state;
    bool esAdmin = false;

    if (authState is Authenticated) {
      if ((authBloc.state as Authenticated).usuario.esAdmin != null) {
        esAdmin = (authBloc.state as Authenticated).usuario.esAdmin;
      }
      return SafeArea(
        child: Drawer(
          child: Column(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: ListView(
                  children: <Widget>[
                    Container(
                      color: Theme.of(context).primaryColor,
                      height: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: UserAccountsDrawerHeader(
                          accountName: Text(
                            esAdmin ? "Administrador" : "Inspector",
                            style: const TextStyle(fontSize: 15),
                          ),
                          accountEmail: Text(authState.usuario.documento),
                          currentAccountPicture: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColorLight,
                            child: Text(
                              authState.usuario.documento[0],
                              style:  TextStyle(fontSize: 50, color: Theme.of(context).accentColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Opciones(esAdmin: esAdmin),
                  ],
                ),
              ),
              LogOut(),
            ],
          ),
        ),
      );
    } else {
      return const Text("error");
    }
  }
}

class Opciones extends StatelessWidget {
  final bool esAdmin;

  const Opciones({Key key, this.esAdmin}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    if (esAdmin) {
      return Column(
        children: <Widget>[
          Card(
            child: ListTile(
                focusColor: Colors.yellow,
                selectedTileColor: Theme.of(context).accentColor,
                title: const Text(
                    'Cuestionarios', //TODO: mostrar el numero de  cuestionarios creados pendientes por subir
                    style: TextStyle(/* color: Colors.white ,*/ fontSize: 15)),
                leading: const Icon(
                  Icons.list_alt,
                  color: Colors.black, /* color: Colors.white, */
                ),
                onTap: () => {
                      ExtendedNavigator.of(context).pop(),
                      ExtendedNavigator.of(context)
                          .replace(Routes.cuestionariosPage),
                    }),
          ),
          Card(
            child: ListTile(
              selectedTileColor: Theme.of(context).accentColor,
              title: const Text(
                  'Borradores', //TODO: mostrar el numero de  inspecciones creadas pendientes por subir
                  style: TextStyle(/* color: Colors.white ,*/ fontSize: 15)),
              leading: const Icon(
                Icons.list,
                color: Colors.black, /* color: Colors.white, */
              ),
              onTap: () =>
                  ExtendedNavigator.of(context).replace(Routes.borradoresPage),
            ),
          ),
          const SizedBox(height: 5.0),
          LimpiezaBase(),
          const SizedBox(height: 5.0),
          SincronizarConGomac(),
          const SizedBox(height: 5.0),
          Card(
            child: ListTile(
              title: const Text('Ver base de datos',
                  style: TextStyle(color: Colors.black, fontSize: 15)),
              leading: const Icon(
                Icons.storage,
                color: Colors.black,
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MoorDbViewer(
                      getIt<Database>(),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 5.0),
        ],
      );
    } else {
      return Column(
        children: [
          Card(
            child: ListTile(
              selectedTileColor: Theme.of(context).accentColor,
              title: const Text(
                  'Borradores', //TODO: mostrar el numero de  inspecciones creadas pendientes por subir
                  style: TextStyle(/* color: Colors.white ,*/ fontSize: 15)),
              leading: const Icon(
                Icons.list,
                color: Colors.black, /* color: Colors.white, */
              ),
              onTap: () =>
                  ExtendedNavigator.of(context).replace(Routes.borradoresPage),
            ),
          ),
          LimpiezaBase(),
          SincronizarConGomac(),
        ],
      );
    }
  }
}

class LogOut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        /* 
                    alignment: FractionalOffset.bottomCenter, */
        child: ListTile(
            title: const Text('Cerrar Sesión'),
            leading: const Icon(Icons.exit_to_app, color: Colors.black),
            onTap: () => authBloc.add(const AuthEvent.loggingOut())),
      ),
    );
  }
}

class SincronizarConGomac extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        selectedTileColor: Theme.of(context).accentColor,
        title: const Text('Sincronizar con GOMAC',
            style: TextStyle(/* color: Colors.white ,*/ fontSize: 15)),
        leading: const Icon(
          Icons.sync,
          color: Colors.black, /* color: Colors.white, */
        ),
        onTap: () async {
          await ExtendedNavigator.of(context).pushSincronizacionPage();
          ExtendedNavigator.of(context).pop();
        },
      ),
    );
  }
}

class LimpiezaBase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cancelButton = FlatButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text("Cancelar",
          style: TextStyle(
              color: Theme.of(context).accentColor)), // OJO con el context
    );
    final Widget continueButton = FlatButton(
      onPressed: () {
        Navigator.of(context).pop();
        getIt<Database>().limpiezaBD();
        Scaffold.of(context).showSnackBar(const SnackBar(
          content: Text('La limpieza de datos ha finalizado'),
        ));
      },
      child: Text("Limpiar",
          style: TextStyle(color: Theme.of(context).accentColor)),
    );
    // set up the AlertDialog
    final alert = AlertDialog(
      title: Text(
        "Alerta",
        style: TextStyle(color: Theme.of(context).accentColor),
      ),
      content: RichText(
        text: TextSpan(
          text:
              'Si limpia la base de datos, perderá todos los borradores que tenga.\n\n',
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
          children: <TextSpan>[
            TextSpan(
              text: 'IMPORTANTE: ',
              style: TextStyle(
                color: Theme.of(context).accentColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text:
                  'debe sincronizar nuevamente con GOMAC después de la limpieza',
              style:
                  TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
            ),
          ],
        ),
      ),

      /* Text(
          "Si limpia la base de datos, perderá todos los borradores que tenga.\n\nIMPORTANTE: debe sincronizar nuevamente con GOMAC después de la limpieza",
          style: TextStyle(color: Theme.of(context).hintColor)), */
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    return Card(
      child: ListTile(
        title: const Text(
          'Limpiar datos de la app',
          style: TextStyle(/* color: Colors.white, */ fontSize: 15),
        ),
        leading: const Icon(
          Icons.cleaning_services,
          color: Colors.black,
        ),
        onTap: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        ),
      ),
    );
  }
}