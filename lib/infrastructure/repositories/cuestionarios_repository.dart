import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:inspecciones/core/error/exceptions.dart';
import 'package:inspecciones/domain/api/api_failure.dart';
import 'package:inspecciones/infrastructure/datasources/remote_datasource.dart';
import 'package:inspecciones/infrastructure/moor_database.dart';
import 'package:inspecciones/infrastructure/repositories/fotos_repository.dart';
import 'package:inspecciones/infrastructure/tablas_unidas.dart';
import 'package:path/path.dart' as p;

class CuestionariosRepository {
  final InspeccionesRemoteDataSource _api;
  final MoorDatabase _db;
  final FotosRepository _fotosRepository;

  CuestionariosRepository(this._db, this._api, this._fotosRepository);

  Future<Either<ApiFailure, Unit>> subirCuestionariosPendientes() async {
    //TODO: subir cada uno, o todos a la vez para mas eficiencia
    throw UnimplementedError();
  }

  /// Envia [cuestionario] al server.
  Future<Either<ApiFailure, Unit>> subirCuestionario(
      Cuestionario cuestionario) async {
    /// Json con info de [cuestionario] y sus respectivos bloques.
    final cues = await _db.getCuestionarioCompletoAsJson(cuestionario);
    log(jsonEncode(cues));
    try {
      log(jsonEncode(cues));
      await _api.postRecurso('cuestionarios-completos', cues);

      /// Como los cuestionarios quedan en el celular, se marca como subidos para que no se envíe al server un cuestionario que ya existe.
      /// cambia [cuestionario.esLocal] = false.
      await _db.marcarCuestionarioSubido(cuestionario);

      /// Usado para el nombre de la carpeta de las fotos
      final idDocumento = cues['id'].toString();

      final fotos = await _fotosRepository.getFotosDeDocumento(
        Categoria.cuestionario,
        identificador: idDocumento,
      );
      await _api.subirFotos(fotos, idDocumento, Categoria.cuestionario);
      return right(unit);
    } on TimeoutException {
      return const Left(ApiFailure.noHayConexionAlServidor());
    } on CredencialesException catch (e) {
      return Left(ApiFailure.serverError(jsonEncode(e.respuesta)));
    } on InternetException {
      return const Left(ApiFailure.noHayInternet());
    } on ServerException catch (e) {
      return Left(ApiFailure.serverError(jsonEncode(e.respuesta)));
    }
  }

  /// Descarga los cuestionarios y todo lo necesario para tratarlos:
  /// activos, sistemas, contratistas y subsistemas
  /// En caso de que ya exista el archivo, lo borra y lo descarga de nuevo
  Future<String?> descargarCuestionarios(
      String savedir, String nombreJson) async {
    final file = File(p.join(savedir, nombreJson));
    if (await file.exists()) {
      await file.delete();
    }
    _api.descargaFlutterDownloader('server', savedir, nombreJson);
  }

  /// Descarga todas las fotos de todos los cuestionarios
  Future descargarFotos(String savedir, String nombreZip) async {
    _api.descargaFlutterDownloader(
        '/media/fotos-app-inspecciones/cuestionarios.zip', savedir, nombreZip);
  }

  Stream<List<Cuestionario>> getCuestionariosLocales() =>
      _db.creacionDao.watchCuestionarios();

  Future eliminarCuestionario(Cuestionario cuestionario) =>
      _db.creacionDao.eliminarCuestionario(cuestionario);

  Future<CuestionarioConContratistaYModelos> getModelosYContratista(
          int cuestionarioId) =>
      _db.creacionDao.getModelosYContratista(cuestionarioId);

  Future<List<IBloqueOrdenable>> cargarCuestionario(int cuestionarioId) =>
      _db.creacionDao.cargarCuestionario(cuestionarioId);

  Future<List<Cuestionario>> getCuestionarios(
          String tipoDeInspeccion, List<String> modelos) =>
      _db.creacionDao.getCuestionarios(tipoDeInspeccion, modelos);

  Future<List<String>> getTiposDeInspecciones() =>
      _db.creacionDao.getTiposDeInspecciones();

  Future<List<String>> getModelos() => _db.creacionDao.getModelos();

  Future<List<Contratista>> getContratistas() =>
      _db.creacionDao.getContratistas();

  Future<List<Sistema>> getSistemas() => _db.creacionDao.getSistemas();
  Future<Sistema> getSistemaPorId(int sistemaId) =>
      _db.creacionDao.getSistemaPorId(sistemaId);
  Future<SubSistema> getSubSistemaPorId(int subSistemaId) =>
      _db.creacionDao.getSubSistemaPorId(subSistemaId);
  Future<List<SubSistema>> getSubSistemas(Sistema sistema) =>
      _db.creacionDao.getSubSistemas(sistema);

  Future guardarCuestionario(
    CuestionariosCompanion cuestionario,
    List<CuestionarioDeModelosCompanion> cuestionariosDeModelos,
    List<Object> bloquesForm,
  ) =>
      _db.creacionDao.guardarCuestionario(
        cuestionario,
        cuestionariosDeModelos,
        bloquesForm,
      );
}
