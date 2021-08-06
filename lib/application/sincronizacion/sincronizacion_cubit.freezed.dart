// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides

part of 'sincronizacion_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more informations: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
class _$TaskTearOff {
  const _$TaskTearOff();

  _Task call(
      {required String id,
      required DownloadTaskStatus status,
      required int progress}) {
    return _Task(
      id: id,
      status: status,
      progress: progress,
    );
  }
}

/// @nodoc
const $Task = _$TaskTearOff();

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  DownloadTaskStatus get status => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res>;
  $Res call({String id, DownloadTaskStatus status, int progress});
}

/// @nodoc
class _$TaskCopyWithImpl<$Res> implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

  final Task _value;
  // ignore: unused_field
  final $Res Function(Task) _then;

  @override
  $Res call({
    Object? id = freezed,
    Object? status = freezed,
    Object? progress = freezed,
  }) {
    return _then(_value.copyWith(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: status == freezed
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadTaskStatus,
      progress: progress == freezed
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
abstract class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) then) =
      __$TaskCopyWithImpl<$Res>;
  @override
  $Res call({String id, DownloadTaskStatus status, int progress});
}

/// @nodoc
class __$TaskCopyWithImpl<$Res> extends _$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(_Task _value, $Res Function(_Task) _then)
      : super(_value, (v) => _then(v as _Task));

  @override
  _Task get _value => super._value as _Task;

  @override
  $Res call({
    Object? id = freezed,
    Object? status = freezed,
    Object? progress = freezed,
  }) {
    return _then(_Task(
      id: id == freezed
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: status == freezed
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadTaskStatus,
      progress: progress == freezed
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_Task with DiagnosticableTreeMixin implements _Task {
  _$_Task({required this.id, required this.status, required this.progress});

  @override
  final String id;
  @override
  final DownloadTaskStatus status;
  @override
  final int progress;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Task(id: $id, status: $status, progress: $progress)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Task'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('progress', progress));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _Task &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.progress, progress) ||
                const DeepCollectionEquality()
                    .equals(other.progress, progress)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(progress);

  @JsonKey(ignore: true)
  @override
  _$TaskCopyWith<_Task> get copyWith =>
      __$TaskCopyWithImpl<_Task>(this, _$identity);
}

abstract class _Task implements Task {
  factory _Task(
      {required String id,
      required DownloadTaskStatus status,
      required int progress}) = _$_Task;

  @override
  String get id => throw _privateConstructorUsedError;
  @override
  DownloadTaskStatus get status => throw _privateConstructorUsedError;
  @override
  int get progress => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$TaskCopyWith<_Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
class _$SincronizacionStateTearOff {
  const _$SincronizacionStateTearOff();

  _SincronizacionState call(
      {bool cargado = false,
      required Task task,
      required List<dynamic> info,
      required int paso}) {
    return _SincronizacionState(
      cargado: cargado,
      task: task,
      info: info,
      paso: paso,
    );
  }
}

/// @nodoc
const $SincronizacionState = _$SincronizacionStateTearOff();

/// @nodoc
mixin _$SincronizacionState {
  bool get cargado => throw _privateConstructorUsedError;
  Task get task => throw _privateConstructorUsedError;

  /// lista que guarda las novedades en un String por cada paso de la sincronización.
  List<dynamic> get info => throw _privateConstructorUsedError;

  /// Etapa de la sincronización: 1-Descarga de cuestionarios, 2- Instalación de la Bd,
  ///  3- Descarga de fotos y 4- Sincronización finalizada.
  int get paso => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SincronizacionStateCopyWith<SincronizacionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SincronizacionStateCopyWith<$Res> {
  factory $SincronizacionStateCopyWith(
          SincronizacionState value, $Res Function(SincronizacionState) then) =
      _$SincronizacionStateCopyWithImpl<$Res>;
  $Res call({bool cargado, Task task, List<dynamic> info, int paso});

  $TaskCopyWith<$Res> get task;
}

/// @nodoc
class _$SincronizacionStateCopyWithImpl<$Res>
    implements $SincronizacionStateCopyWith<$Res> {
  _$SincronizacionStateCopyWithImpl(this._value, this._then);

  final SincronizacionState _value;
  // ignore: unused_field
  final $Res Function(SincronizacionState) _then;

  @override
  $Res call({
    Object? cargado = freezed,
    Object? task = freezed,
    Object? info = freezed,
    Object? paso = freezed,
  }) {
    return _then(_value.copyWith(
      cargado: cargado == freezed
          ? _value.cargado
          : cargado // ignore: cast_nullable_to_non_nullable
              as bool,
      task: task == freezed
          ? _value.task
          : task // ignore: cast_nullable_to_non_nullable
              as Task,
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      paso: paso == freezed
          ? _value.paso
          : paso // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }

  @override
  $TaskCopyWith<$Res> get task {
    return $TaskCopyWith<$Res>(_value.task, (value) {
      return _then(_value.copyWith(task: value));
    });
  }
}

/// @nodoc
abstract class _$SincronizacionStateCopyWith<$Res>
    implements $SincronizacionStateCopyWith<$Res> {
  factory _$SincronizacionStateCopyWith(_SincronizacionState value,
          $Res Function(_SincronizacionState) then) =
      __$SincronizacionStateCopyWithImpl<$Res>;
  @override
  $Res call({bool cargado, Task task, List<dynamic> info, int paso});

  @override
  $TaskCopyWith<$Res> get task;
}

/// @nodoc
class __$SincronizacionStateCopyWithImpl<$Res>
    extends _$SincronizacionStateCopyWithImpl<$Res>
    implements _$SincronizacionStateCopyWith<$Res> {
  __$SincronizacionStateCopyWithImpl(
      _SincronizacionState _value, $Res Function(_SincronizacionState) _then)
      : super(_value, (v) => _then(v as _SincronizacionState));

  @override
  _SincronizacionState get _value => super._value as _SincronizacionState;

  @override
  $Res call({
    Object? cargado = freezed,
    Object? task = freezed,
    Object? info = freezed,
    Object? paso = freezed,
  }) {
    return _then(_SincronizacionState(
      cargado: cargado == freezed
          ? _value.cargado
          : cargado // ignore: cast_nullable_to_non_nullable
              as bool,
      task: task == freezed
          ? _value.task
          : task // ignore: cast_nullable_to_non_nullable
              as Task,
      info: info == freezed
          ? _value.info
          : info // ignore: cast_nullable_to_non_nullable
              as List<dynamic>,
      paso: paso == freezed
          ? _value.paso
          : paso // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$_SincronizacionState
    with DiagnosticableTreeMixin
    implements _SincronizacionState {
  _$_SincronizacionState(
      {this.cargado = false,
      required this.task,
      required this.info,
      required this.paso});

  @JsonKey(defaultValue: false)
  @override
  final bool cargado;
  @override
  final Task task;
  @override

  /// lista que guarda las novedades en un String por cada paso de la sincronización.
  final List<dynamic> info;
  @override

  /// Etapa de la sincronización: 1-Descarga de cuestionarios, 2- Instalación de la Bd,
  ///  3- Descarga de fotos y 4- Sincronización finalizada.
  final int paso;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SincronizacionState(cargado: $cargado, task: $task, info: $info, paso: $paso)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SincronizacionState'))
      ..add(DiagnosticsProperty('cargado', cargado))
      ..add(DiagnosticsProperty('task', task))
      ..add(DiagnosticsProperty('info', info))
      ..add(DiagnosticsProperty('paso', paso));
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is _SincronizacionState &&
            (identical(other.cargado, cargado) ||
                const DeepCollectionEquality()
                    .equals(other.cargado, cargado)) &&
            (identical(other.task, task) ||
                const DeepCollectionEquality().equals(other.task, task)) &&
            (identical(other.info, info) ||
                const DeepCollectionEquality().equals(other.info, info)) &&
            (identical(other.paso, paso) ||
                const DeepCollectionEquality().equals(other.paso, paso)));
  }

  @override
  int get hashCode =>
      runtimeType.hashCode ^
      const DeepCollectionEquality().hash(cargado) ^
      const DeepCollectionEquality().hash(task) ^
      const DeepCollectionEquality().hash(info) ^
      const DeepCollectionEquality().hash(paso);

  @JsonKey(ignore: true)
  @override
  _$SincronizacionStateCopyWith<_SincronizacionState> get copyWith =>
      __$SincronizacionStateCopyWithImpl<_SincronizacionState>(
          this, _$identity);
}

abstract class _SincronizacionState implements SincronizacionState {
  factory _SincronizacionState(
      {bool cargado,
      required Task task,
      required List<dynamic> info,
      required int paso}) = _$_SincronizacionState;

  @override
  bool get cargado => throw _privateConstructorUsedError;
  @override
  Task get task => throw _privateConstructorUsedError;
  @override

  /// lista que guarda las novedades en un String por cada paso de la sincronización.
  List<dynamic> get info => throw _privateConstructorUsedError;
  @override

  /// Etapa de la sincronización: 1-Descarga de cuestionarios, 2- Instalación de la Bd,
  ///  3- Descarga de fotos y 4- Sincronización finalizada.
  int get paso => throw _privateConstructorUsedError;
  @override
  @JsonKey(ignore: true)
  _$SincronizacionStateCopyWith<_SincronizacionState> get copyWith =>
      throw _privateConstructorUsedError;
}
