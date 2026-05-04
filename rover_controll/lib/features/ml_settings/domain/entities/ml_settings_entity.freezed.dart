// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ml_settings_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ObjectDetectionSettings {
  ObjectDetectionMode get mode => throw _privateConstructorUsedError;
  double get confidenceThreshold => throw _privateConstructorUsedError;
  int get intervalMs => throw _privateConstructorUsedError;
  bool get showDiagnostics => throw _privateConstructorUsedError;

  /// Create a copy of ObjectDetectionSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ObjectDetectionSettingsCopyWith<ObjectDetectionSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ObjectDetectionSettingsCopyWith<$Res> {
  factory $ObjectDetectionSettingsCopyWith(
    ObjectDetectionSettings value,
    $Res Function(ObjectDetectionSettings) then,
  ) = _$ObjectDetectionSettingsCopyWithImpl<$Res, ObjectDetectionSettings>;
  @useResult
  $Res call({
    ObjectDetectionMode mode,
    double confidenceThreshold,
    int intervalMs,
    bool showDiagnostics,
  });
}

/// @nodoc
class _$ObjectDetectionSettingsCopyWithImpl<
  $Res,
  $Val extends ObjectDetectionSettings
>
    implements $ObjectDetectionSettingsCopyWith<$Res> {
  _$ObjectDetectionSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ObjectDetectionSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? confidenceThreshold = null,
    Object? intervalMs = null,
    Object? showDiagnostics = null,
  }) {
    return _then(
      _value.copyWith(
            mode: null == mode
                ? _value.mode
                : mode // ignore: cast_nullable_to_non_nullable
                      as ObjectDetectionMode,
            confidenceThreshold: null == confidenceThreshold
                ? _value.confidenceThreshold
                : confidenceThreshold // ignore: cast_nullable_to_non_nullable
                      as double,
            intervalMs: null == intervalMs
                ? _value.intervalMs
                : intervalMs // ignore: cast_nullable_to_non_nullable
                      as int,
            showDiagnostics: null == showDiagnostics
                ? _value.showDiagnostics
                : showDiagnostics // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ObjectDetectionSettingsImplCopyWith<$Res>
    implements $ObjectDetectionSettingsCopyWith<$Res> {
  factory _$$ObjectDetectionSettingsImplCopyWith(
    _$ObjectDetectionSettingsImpl value,
    $Res Function(_$ObjectDetectionSettingsImpl) then,
  ) = __$$ObjectDetectionSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ObjectDetectionMode mode,
    double confidenceThreshold,
    int intervalMs,
    bool showDiagnostics,
  });
}

/// @nodoc
class __$$ObjectDetectionSettingsImplCopyWithImpl<$Res>
    extends
        _$ObjectDetectionSettingsCopyWithImpl<
          $Res,
          _$ObjectDetectionSettingsImpl
        >
    implements _$$ObjectDetectionSettingsImplCopyWith<$Res> {
  __$$ObjectDetectionSettingsImplCopyWithImpl(
    _$ObjectDetectionSettingsImpl _value,
    $Res Function(_$ObjectDetectionSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ObjectDetectionSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? confidenceThreshold = null,
    Object? intervalMs = null,
    Object? showDiagnostics = null,
  }) {
    return _then(
      _$ObjectDetectionSettingsImpl(
        mode: null == mode
            ? _value.mode
            : mode // ignore: cast_nullable_to_non_nullable
                  as ObjectDetectionMode,
        confidenceThreshold: null == confidenceThreshold
            ? _value.confidenceThreshold
            : confidenceThreshold // ignore: cast_nullable_to_non_nullable
                  as double,
        intervalMs: null == intervalMs
            ? _value.intervalMs
            : intervalMs // ignore: cast_nullable_to_non_nullable
                  as int,
        showDiagnostics: null == showDiagnostics
            ? _value.showDiagnostics
            : showDiagnostics // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$ObjectDetectionSettingsImpl implements _ObjectDetectionSettings {
  const _$ObjectDetectionSettingsImpl({
    this.mode = ObjectDetectionMode.off,
    this.confidenceThreshold = 0.45,
    this.intervalMs = 800,
    this.showDiagnostics = true,
  });

  @override
  @JsonKey()
  final ObjectDetectionMode mode;
  @override
  @JsonKey()
  final double confidenceThreshold;
  @override
  @JsonKey()
  final int intervalMs;
  @override
  @JsonKey()
  final bool showDiagnostics;

  @override
  String toString() {
    return 'ObjectDetectionSettings(mode: $mode, confidenceThreshold: $confidenceThreshold, intervalMs: $intervalMs, showDiagnostics: $showDiagnostics)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ObjectDetectionSettingsImpl &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.confidenceThreshold, confidenceThreshold) ||
                other.confidenceThreshold == confidenceThreshold) &&
            (identical(other.intervalMs, intervalMs) ||
                other.intervalMs == intervalMs) &&
            (identical(other.showDiagnostics, showDiagnostics) ||
                other.showDiagnostics == showDiagnostics));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    mode,
    confidenceThreshold,
    intervalMs,
    showDiagnostics,
  );

  /// Create a copy of ObjectDetectionSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ObjectDetectionSettingsImplCopyWith<_$ObjectDetectionSettingsImpl>
  get copyWith =>
      __$$ObjectDetectionSettingsImplCopyWithImpl<
        _$ObjectDetectionSettingsImpl
      >(this, _$identity);
}

abstract class _ObjectDetectionSettings implements ObjectDetectionSettings {
  const factory _ObjectDetectionSettings({
    final ObjectDetectionMode mode,
    final double confidenceThreshold,
    final int intervalMs,
    final bool showDiagnostics,
  }) = _$ObjectDetectionSettingsImpl;

  @override
  ObjectDetectionMode get mode;
  @override
  double get confidenceThreshold;
  @override
  int get intervalMs;
  @override
  bool get showDiagnostics;

  /// Create a copy of ObjectDetectionSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ObjectDetectionSettingsImplCopyWith<_$ObjectDetectionSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MlSettingsEntity {
  ObjectDetectionSettings get objectDetection =>
      throw _privateConstructorUsedError;

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MlSettingsEntityCopyWith<MlSettingsEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MlSettingsEntityCopyWith<$Res> {
  factory $MlSettingsEntityCopyWith(
    MlSettingsEntity value,
    $Res Function(MlSettingsEntity) then,
  ) = _$MlSettingsEntityCopyWithImpl<$Res, MlSettingsEntity>;
  @useResult
  $Res call({ObjectDetectionSettings objectDetection});

  $ObjectDetectionSettingsCopyWith<$Res> get objectDetection;
}

/// @nodoc
class _$MlSettingsEntityCopyWithImpl<$Res, $Val extends MlSettingsEntity>
    implements $MlSettingsEntityCopyWith<$Res> {
  _$MlSettingsEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? objectDetection = null}) {
    return _then(
      _value.copyWith(
            objectDetection: null == objectDetection
                ? _value.objectDetection
                : objectDetection // ignore: cast_nullable_to_non_nullable
                      as ObjectDetectionSettings,
          )
          as $Val,
    );
  }

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ObjectDetectionSettingsCopyWith<$Res> get objectDetection {
    return $ObjectDetectionSettingsCopyWith<$Res>(_value.objectDetection, (
      value,
    ) {
      return _then(_value.copyWith(objectDetection: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MlSettingsEntityImplCopyWith<$Res>
    implements $MlSettingsEntityCopyWith<$Res> {
  factory _$$MlSettingsEntityImplCopyWith(
    _$MlSettingsEntityImpl value,
    $Res Function(_$MlSettingsEntityImpl) then,
  ) = __$$MlSettingsEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({ObjectDetectionSettings objectDetection});

  @override
  $ObjectDetectionSettingsCopyWith<$Res> get objectDetection;
}

/// @nodoc
class __$$MlSettingsEntityImplCopyWithImpl<$Res>
    extends _$MlSettingsEntityCopyWithImpl<$Res, _$MlSettingsEntityImpl>
    implements _$$MlSettingsEntityImplCopyWith<$Res> {
  __$$MlSettingsEntityImplCopyWithImpl(
    _$MlSettingsEntityImpl _value,
    $Res Function(_$MlSettingsEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? objectDetection = null}) {
    return _then(
      _$MlSettingsEntityImpl(
        objectDetection: null == objectDetection
            ? _value.objectDetection
            : objectDetection // ignore: cast_nullable_to_non_nullable
                  as ObjectDetectionSettings,
      ),
    );
  }
}

/// @nodoc

class _$MlSettingsEntityImpl implements _MlSettingsEntity {
  const _$MlSettingsEntityImpl({
    this.objectDetection = const ObjectDetectionSettings(),
  });

  @override
  @JsonKey()
  final ObjectDetectionSettings objectDetection;

  @override
  String toString() {
    return 'MlSettingsEntity(objectDetection: $objectDetection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MlSettingsEntityImpl &&
            (identical(other.objectDetection, objectDetection) ||
                other.objectDetection == objectDetection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, objectDetection);

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MlSettingsEntityImplCopyWith<_$MlSettingsEntityImpl> get copyWith =>
      __$$MlSettingsEntityImplCopyWithImpl<_$MlSettingsEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _MlSettingsEntity implements MlSettingsEntity {
  const factory _MlSettingsEntity({
    final ObjectDetectionSettings objectDetection,
  }) = _$MlSettingsEntityImpl;

  @override
  ObjectDetectionSettings get objectDetection;

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MlSettingsEntityImplCopyWith<_$MlSettingsEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
