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
mixin _$MlSettingsEntity {
  ObjectDetectionSettings get objectDetection =>
      throw _privateConstructorUsedError;
  MotionPatternSettings get motionPattern => throw _privateConstructorUsedError;

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
  $Res call({
    ObjectDetectionSettings objectDetection,
    MotionPatternSettings motionPattern,
  });

  $ObjectDetectionSettingsCopyWith<$Res> get objectDetection;
  $MotionPatternSettingsCopyWith<$Res> get motionPattern;
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
  $Res call({Object? objectDetection = null, Object? motionPattern = null}) {
    return _then(
      _value.copyWith(
            objectDetection: null == objectDetection
                ? _value.objectDetection
                : objectDetection // ignore: cast_nullable_to_non_nullable
                      as ObjectDetectionSettings,
            motionPattern: null == motionPattern
                ? _value.motionPattern
                : motionPattern // ignore: cast_nullable_to_non_nullable
                      as MotionPatternSettings,
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

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MotionPatternSettingsCopyWith<$Res> get motionPattern {
    return $MotionPatternSettingsCopyWith<$Res>(_value.motionPattern, (value) {
      return _then(_value.copyWith(motionPattern: value) as $Val);
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
  $Res call({
    ObjectDetectionSettings objectDetection,
    MotionPatternSettings motionPattern,
  });

  @override
  $ObjectDetectionSettingsCopyWith<$Res> get objectDetection;
  @override
  $MotionPatternSettingsCopyWith<$Res> get motionPattern;
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
  $Res call({Object? objectDetection = null, Object? motionPattern = null}) {
    return _then(
      _$MlSettingsEntityImpl(
        objectDetection: null == objectDetection
            ? _value.objectDetection
            : objectDetection // ignore: cast_nullable_to_non_nullable
                  as ObjectDetectionSettings,
        motionPattern: null == motionPattern
            ? _value.motionPattern
            : motionPattern // ignore: cast_nullable_to_non_nullable
                  as MotionPatternSettings,
      ),
    );
  }
}

/// @nodoc

class _$MlSettingsEntityImpl implements _MlSettingsEntity {
  const _$MlSettingsEntityImpl({
    this.objectDetection = const ObjectDetectionSettings(),
    this.motionPattern = const MotionPatternSettings(),
  });

  @override
  @JsonKey()
  final ObjectDetectionSettings objectDetection;
  @override
  @JsonKey()
  final MotionPatternSettings motionPattern;

  @override
  String toString() {
    return 'MlSettingsEntity(objectDetection: $objectDetection, motionPattern: $motionPattern)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MlSettingsEntityImpl &&
            (identical(other.objectDetection, objectDetection) ||
                other.objectDetection == objectDetection) &&
            (identical(other.motionPattern, motionPattern) ||
                other.motionPattern == motionPattern));
  }

  @override
  int get hashCode => Object.hash(runtimeType, objectDetection, motionPattern);

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
    final MotionPatternSettings motionPattern,
  }) = _$MlSettingsEntityImpl;

  @override
  ObjectDetectionSettings get objectDetection;
  @override
  MotionPatternSettings get motionPattern;

  /// Create a copy of MlSettingsEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MlSettingsEntityImplCopyWith<_$MlSettingsEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
