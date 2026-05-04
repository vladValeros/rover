// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:rover_controll/core/network/dio_client.dart' as _i990;
import 'package:rover_controll/features/connection/data/datasources/connection_local_datasource.dart'
    as _i940;
import 'package:rover_controll/features/connection/data/datasources/connection_remote_datasource.dart'
    as _i20;
import 'package:rover_controll/features/connection/data/repositories/connection_repository_impl.dart'
    as _i967;
import 'package:rover_controll/features/connection/domain/repositories/connection_repository.dart'
    as _i12;
import 'package:rover_controll/features/connection/domain/usecases/discover_rover_ip_usecase.dart'
    as _i3;
import 'package:rover_controll/features/connection/domain/usecases/load_saved_connection_usecase.dart'
    as _i90;
import 'package:rover_controll/features/connection/domain/usecases/save_connection_usecase.dart'
    as _i423;
import 'package:rover_controll/features/connection/domain/usecases/test_connection_usecase.dart'
    as _i148;
import 'package:rover_controll/features/connection/presentation/controllers/connection_cubit.dart'
    as _i947;
import 'package:rover_controll/features/ml_settings/data/datasources/ml_settings_local_datasource.dart'
    as _i125;
import 'package:rover_controll/features/ml_settings/presentation/controllers/ml_settings_cubit.dart'
    as _i356;
import 'package:rover_controll/features/rover_control/data/datasources/rover_remote_datasource.dart'
    as _i880;
import 'package:rover_controll/features/rover_control/data/repositories/rover_control_repository_impl.dart'
    as _i390;
import 'package:rover_controll/features/rover_control/domain/repositories/rover_control_repository.dart'
    as _i553;
import 'package:rover_controll/features/rover_control/domain/usecases/send_rover_command_usecase.dart'
    as _i65;
import 'package:rover_controll/features/rover_control/presentation/controllers/rover_control_cubit.dart'
    as _i600;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i990.DioClient>(() => _i990.DioClient());
    gh.lazySingleton<_i940.ConnectionLocalDatasource>(
      () => _i940.ConnectionLocalDatasource(),
    );
    gh.lazySingleton<_i125.MlSettingsLocalDatasource>(
      () => _i125.MlSettingsLocalDatasource(),
    );
    gh.lazySingleton<_i356.MlSettingsCubit>(
      () => _i356.MlSettingsCubit(gh<_i125.MlSettingsLocalDatasource>()),
    );
    gh.lazySingleton<_i20.ConnectionRemoteDatasource>(
      () => _i20.ConnectionRemoteDatasource(gh<_i990.DioClient>()),
    );
    gh.lazySingleton<_i880.RoverRemoteDatasource>(
      () => _i880.RoverRemoteDatasource(gh<_i990.DioClient>()),
    );
    gh.lazySingleton<_i553.RoverControlRepository>(
      () => _i390.RoverControlRepositoryImpl(gh<_i880.RoverRemoteDatasource>()),
    );
    gh.lazySingleton<_i65.SendRoverCommandUseCase>(
      () => _i65.SendRoverCommandUseCase(gh<_i553.RoverControlRepository>()),
    );
    gh.factory<_i600.RoverControlCubit>(
      () => _i600.RoverControlCubit(gh<_i65.SendRoverCommandUseCase>()),
    );
    gh.lazySingleton<_i12.ConnectionRepository>(
      () => _i967.ConnectionRepositoryImpl(
        gh<_i940.ConnectionLocalDatasource>(),
        gh<_i20.ConnectionRemoteDatasource>(),
      ),
    );
    gh.lazySingleton<_i3.DiscoverRoverIpUseCase>(
      () => _i3.DiscoverRoverIpUseCase(gh<_i12.ConnectionRepository>()),
    );
    gh.lazySingleton<_i90.LoadSavedConnectionUseCase>(
      () => _i90.LoadSavedConnectionUseCase(gh<_i12.ConnectionRepository>()),
    );
    gh.lazySingleton<_i423.SaveConnectionUseCase>(
      () => _i423.SaveConnectionUseCase(gh<_i12.ConnectionRepository>()),
    );
    gh.lazySingleton<_i148.TestConnectionUseCase>(
      () => _i148.TestConnectionUseCase(gh<_i12.ConnectionRepository>()),
    );
    gh.factory<_i947.ConnectionCubit>(
      () => _i947.ConnectionCubit(
        gh<_i3.DiscoverRoverIpUseCase>(),
        gh<_i90.LoadSavedConnectionUseCase>(),
        gh<_i423.SaveConnectionUseCase>(),
        gh<_i148.TestConnectionUseCase>(),
      ),
    );
    return this;
  }
}
