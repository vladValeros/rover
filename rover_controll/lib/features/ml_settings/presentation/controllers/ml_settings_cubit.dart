import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/ml_settings_local_datasource.dart';
import '../../domain/entities/ml_settings_entity.dart';
import 'ml_settings_state.dart';

@lazySingleton
class MlSettingsCubit extends Cubit<MlSettingsState> {
  MlSettingsCubit(this._datasource) : super(const MlSettingsState.loading());

  final MlSettingsLocalDatasource _datasource;

  Future<void> load() async {
    final settings = await _datasource.load();
    emit(MlSettingsState.loaded(settings));
  }

  /// Update object detection settings and persist them.
  Future<void> updateObjectDetection(ObjectDetectionSettings settings) async {
    final current = state.whenOrNull(loaded: (s) => s);
    if (current == null) return;
    final updated = current.copyWith(objectDetection: settings);
    emit(MlSettingsState.loaded(updated));
    await _datasource.saveObjectDetection(settings);
  }

  // Future ML features can add their own update methods here, e.g.:
  // Future<void> updateMotionDetection(MotionDetectionSettings settings) async { ... }
}
