// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'motion_pattern_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MotionPatternSettings {
  bool get enabled => throw _privateConstructorUsedError;
  MotionPatternType get pattern => throw _privateConstructorUsedError;
  int get forwardMs => throw _privateConstructorUsedError;
  int get turn90Ms => throw _privateConstructorUsedError;
  int get turn180Ms => throw _privateConstructorUsedError;
  int get interStepPauseMs => throw _privateConstructorUsedError;

  /// Create a copy of MotionPatternSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MotionPatternSettingsCopyWith<MotionPatternSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MotionPatternSettingsCopyWith<$Res> {
  factory $MotionPatternSettingsCopyWith(
    MotionPatternSettings value,
    $Res Function(MotionPatternSettings) then,
  ) = _$MotionPatternSettingsCopyWithImpl<$Res, MotionPatternSettings>;
  @useResult
  $Res call({
    bool enabled,
    MotionPatternType pattern,
    int forwardMs,
    int turn90Ms,
    int turn180Ms,
    int interStepPauseMs,
  });
}

/// @nodoc
class _$MotionPatternSettingsCopyWithImpl<
  $Res,
  $Val extends MotionPatternSettings
>
    implements $MotionPatternSettingsCopyWith<$Res> {
  _$MotionPatternSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MotionPatternSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? pattern = null,
    Object? forwardMs = null,
    Object? turn90Ms = null,
    Object? turn180Ms = null,
    Object? interStepPauseMs = null,
  }) {
    return _then(
      _value.copyWith(
            enabled: null == enabled
                ? _value.enabled
                : enabled // ignore: cast_nullable_to_non_nullable
                      as bool,
            pattern: null == pattern
                ? _value.pattern
                : pattern // ignore: cast_nullable_to_non_nullable
                      as MotionPatternType,
            forwardMs: null == forwardMs
                ? _value.forwardMs
                : forwardMs // ignore: cast_nullable_to_non_nullable
                      as int,
            turn90Ms: null == turn90Ms
                ? _value.turn90Ms
                : turn90Ms // ignore: cast_nullable_to_non_nullable
                      as int,
            turn180Ms: null == turn180Ms
                ? _value.turn180Ms
                : turn180Ms // ignore: cast_nullable_to_non_nullable
                      as int,
            interStepPauseMs: null == interStepPauseMs
                ? _value.interStepPauseMs
                : interStepPauseMs // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MotionPatternSettingsImplCopyWith<$Res>
    implements $MotionPatternSettingsCopyWith<$Res> {
  factory _$$MotionPatternSettingsImplCopyWith(
    _$MotionPatternSettingsImpl value,
    $Res Function(_$MotionPatternSettingsImpl) then,
  ) = __$$MotionPatternSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool enabled,
    MotionPatternType pattern,
    int forwardMs,
    int turn90Ms,
    int turn180Ms,
    int interStepPauseMs,
  });
}

/// @nodoc
class __$$MotionPatternSettingsImplCopyWithImpl<$Res>
    extends
        _$MotionPatternSettingsCopyWithImpl<$Res, _$MotionPatternSettingsImpl>
    implements _$$MotionPatternSettingsImplCopyWith<$Res> {
  __$$MotionPatternSettingsImplCopyWithImpl(
    _$MotionPatternSettingsImpl _value,
    $Res Function(_$MotionPatternSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MotionPatternSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? pattern = null,
    Object? forwardMs = null,
    Object? turn90Ms = null,
    Object? turn180Ms = null,
    Object? interStepPauseMs = null,
  }) {
    return _then(
      _$MotionPatternSettingsImpl(
        enabled: null == enabled
            ? _value.enabled
            : enabled // ignore: cast_nullable_to_non_nullable
                  as bool,
        pattern: null == pattern
            ? _value.pattern
            : pattern // ignore: cast_nullable_to_non_nullable
                  as MotionPatternType,
        forwardMs: null == forwardMs
            ? _value.forwardMs
            : forwardMs // ignore: cast_nullable_to_non_nullable
                  as int,
        turn90Ms: null == turn90Ms
            ? _value.turn90Ms
            : turn90Ms // ignore: cast_nullable_to_non_nullable
                  as int,
        turn180Ms: null == turn180Ms
            ? _value.turn180Ms
            : turn180Ms // ignore: cast_nullable_to_non_nullable
                  as int,
        interStepPauseMs: null == interStepPauseMs
            ? _value.interStepPauseMs
            : interStepPauseMs // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$MotionPatternSettingsImpl implements _MotionPatternSettings {
  const _$MotionPatternSettingsImpl({
    this.enabled = false,
    this.pattern = MotionPatternType.box,
    this.forwardMs = 900,
    this.turn90Ms = 520,
    this.turn180Ms = 980,
    this.interStepPauseMs = 120,
  });

  @override
  @JsonKey()
  final bool enabled;
  @override
  @JsonKey()
  final MotionPatternType pattern;
  @override
  @JsonKey()
  final int forwardMs;
  @override
  @JsonKey()
  final int turn90Ms;
  @override
  @JsonKey()
  final int turn180Ms;
  @override
  @JsonKey()
  final int interStepPauseMs;

  @override
  String toString() {
    return 'MotionPatternSettings(enabled: $enabled, pattern: $pattern, forwardMs: $forwardMs, turn90Ms: $turn90Ms, turn180Ms: $turn180Ms, interStepPauseMs: $interStepPauseMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MotionPatternSettingsImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.pattern, pattern) || other.pattern == pattern) &&
            (identical(other.forwardMs, forwardMs) ||
                other.forwardMs == forwardMs) &&
            (identical(other.turn90Ms, turn90Ms) ||
                other.turn90Ms == turn90Ms) &&
            (identical(other.turn180Ms, turn180Ms) ||
                other.turn180Ms == turn180Ms) &&
            (identical(other.interStepPauseMs, interStepPauseMs) ||
                other.interStepPauseMs == interStepPauseMs));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    enabled,
    pattern,
    forwardMs,
    turn90Ms,
    turn180Ms,
    interStepPauseMs,
  );

  /// Create a copy of MotionPatternSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MotionPatternSettingsImplCopyWith<_$MotionPatternSettingsImpl>
  get copyWith =>
      __$$MotionPatternSettingsImplCopyWithImpl<_$MotionPatternSettingsImpl>(
        this,
        _$identity,
      );
}

abstract class _MotionPatternSettings implements MotionPatternSettings {
  const factory _MotionPatternSettings({
    final bool enabled,
    final MotionPatternType pattern,
    final int forwardMs,
    final int turn90Ms,
    final int turn180Ms,
    final int interStepPauseMs,
  }) = _$MotionPatternSettingsImpl;

  @override
  bool get enabled;
  @override
  MotionPatternType get pattern;
  @override
  int get forwardMs;
  @override
  int get turn90Ms;
  @override
  int get turn180Ms;
  @override
  int get interStepPauseMs;

  /// Create a copy of MotionPatternSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MotionPatternSettingsImplCopyWith<_$MotionPatternSettingsImpl>
  get copyWith => throw _privateConstructorUsedError;
}
