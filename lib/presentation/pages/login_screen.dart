
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:inspecciones/application/auth/auth_bloc.dart';
import 'package:inspecciones/infrastructure/repositories/api_model.dart';
import 'package:inspecciones/mvvc/common_widgets.dart';
import 'package:inspecciones/mvvc/form_scaffold.dart';
import 'package:reactive_forms/reactive_forms.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authBloc = Provider.of<AuthBloc>(context);
    return FormScaffold(
      title: Text('Login'),
      body: ReactiveFormBuilder(
        form: () => fb.group({
          'usuario': fb.control('', [Validators.required]),
          'password': fb.control('', [Validators.required]),
        }),
        builder: (context, form, child) {
          return PreguntaCard(
            child: Column(
              children: [
                ReactiveTextField(
                  formControlName: 'usuario',
                  decoration: InputDecoration(
                    labelText: 'Usuario',
                  ),
                ),
                ReactiveTextField(
                  formControlName: 'password',
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                  ),
                ),
                ReactiveFormConsumer(
                  builder: (context, form, child) {
                    return RaisedButton(
                      child: Text('Entrar'),
                      onPressed: form.valid
                          ? () => authBloc.add(
                                LoggingIn(
                                  UserLogin(
                                    username: form.value['usuario'],
                                    password: form.value['password'],
                                  ),
                                ),
                              )
                          : null,
                    );
                  },
                ),
                FlatButton(
                    onPressed: () => print(authBloc.state),
                    child: Text("print state")),
                FlatButton(
                    onPressed: () => authBloc.add(LoggingOut()),
                    child: Text("emit unauth")),
              ],
            ),
          );
        },
      ),
    );
  }
}
