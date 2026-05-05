import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_entity.freezed.dart';

@freezed
abstract class ConnectionEntity with _$ConnectionEntity {
  const factory ConnectionEntity({required String roverIpAddress}) =
      _ConnectionEntity;
}
