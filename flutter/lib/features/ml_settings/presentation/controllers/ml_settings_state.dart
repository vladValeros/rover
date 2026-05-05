import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/ml_settings_entity.dart';

part 'ml_settings_state.freezed.dart';

@freezed
abstract class MlSettingsState with _$MlSettingsState {
  const factory MlSettingsState.loading() = _Loading;
  const factory MlSettingsState.loaded(MlSettingsEntity settings) = _Loaded;
}
