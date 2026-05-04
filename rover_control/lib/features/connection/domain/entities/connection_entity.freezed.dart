// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ConnectionEntity {
  String get roverIpAddress => throw _privateConstructorUsedError;

  /// Create a copy of ConnectionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConnectionEntityCopyWith<ConnectionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConnectionEntityCopyWith<$Res> {
  factory $ConnectionEntityCopyWith(
    ConnectionEntity value,
    $Res Function(ConnectionEntity) then,
  ) = _$ConnectionEntityCopyWithImpl<$Res, ConnectionEntity>;
  @useResult
  $Res call({String roverIpAddress});
}

/// @nodoc
class _$ConnectionEntityCopyWithImpl<$Res, $Val extends ConnectionEntity>
    implements $ConnectionEntityCopyWith<$Res> {
  _$ConnectionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ConnectionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? roverIpAddress = null}) {
    return _then(
      _value.copyWith(
            roverIpAddress: null == roverIpAddress
                ? _value.roverIpAddress
                : roverIpAddress // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ConnectionEntityImplCopyWith<$Res>
    implements $ConnectionEntityCopyWith<$Res> {
  factory _$$ConnectionEntityImplCopyWith(
    _$ConnectionEntityImpl value,
    $Res Function(_$ConnectionEntityImpl) then,
  ) = __$$ConnectionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String roverIpAddress});
}

/// @nodoc
class __$$ConnectionEntityImplCopyWithImpl<$Res>
    extends _$ConnectionEntityCopyWithImpl<$Res, _$ConnectionEntityImpl>
    implements _$$ConnectionEntityImplCopyWith<$Res> {
  __$$ConnectionEntityImplCopyWithImpl(
    _$ConnectionEntityImpl _value,
    $Res Function(_$ConnectionEntityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ConnectionEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? roverIpAddress = null}) {
    return _then(
      _$ConnectionEntityImpl(
        roverIpAddress: null == roverIpAddress
            ? _value.roverIpAddress
            : roverIpAddress // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ConnectionEntityImpl implements _ConnectionEntity {
  const _$ConnectionEntityImpl({required this.roverIpAddress});

  @override
  final String roverIpAddress;

  @override
  String toString() {
    return 'ConnectionEntity(roverIpAddress: $roverIpAddress)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConnectionEntityImpl &&
            (identical(other.roverIpAddress, roverIpAddress) ||
                other.roverIpAddress == roverIpAddress));
  }

  @override
  int get hashCode => Object.hash(runtimeType, roverIpAddress);

  /// Create a copy of ConnectionEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConnectionEntityImplCopyWith<_$ConnectionEntityImpl> get copyWith =>
      __$$ConnectionEntityImplCopyWithImpl<_$ConnectionEntityImpl>(
        this,
        _$identity,
      );
}

abstract class _ConnectionEntity implements ConnectionEntity {
  const factory _ConnectionEntity({required final String roverIpAddress}) =
      _$ConnectionEntityImpl;

  @override
  String get roverIpAddress;

  /// Create a copy of ConnectionEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConnectionEntityImplCopyWith<_$ConnectionEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
