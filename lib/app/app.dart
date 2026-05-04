import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
import '../features/connection/presentation/controllers/connection_cubit.dart';
import 'app_router.dart';
import 'locator.dart';

class RoverApp extends StatelessWidget {
  const RoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ConnectionCubit>()..loadSavedAddress(),
      child: MaterialApp.router(
        title: 'Rover Control',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
