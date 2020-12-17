import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:inspecciones/application/auth/usuario.dart';
import 'package:inspecciones/infrastructure/datasources/local_preferences_datasource.dart';
import 'package:inspecciones/infrastructure/datasources/remote_datasource.dart';
import 'package:inspecciones/infrastructure/repositories/api_model.dart';
import 'package:meta/meta.dart';
import 'package:data_connection_checker/data_connection_checker.dart';

@injectable
class UserRepository {
  final InspeccionesRemoteDataSource api;
  final ILocalPreferencesDataSource localPreferences;

  UserRepository(this.api, this.localPreferences);

  Future<Usuario> authenticateUser({UserLogin userLogin}) async {
    String token;
    if (await hayInternet()) {
      //token = await api.getToken(userLogin);
    }

    final user = Usuario(
        documento: userLogin.documento,
        password: userLogin.password,
        esAdmin: true,
        token: token);
    return user;
  }

  Future<void> saveLocalUser({@required Usuario user}) async {
    // write token with the user to the local database
    await localPreferences.saveUser(user);
  }

  Future<void> deleteLocalUser() async {
    await localPreferences.deleteUser();
  }

  Usuario getLocalUser() {
    final res = localPreferences.getUser();
    return res;
  }

  Future<bool> hayInternet() async => DataConnectionChecker().hasConnection;
}
