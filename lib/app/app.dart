import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/domain/entities/theme_preference.dart';
import '../features/settings/presentation/bloc/settings_bloc.dart';
import '../shared/ui/settings_scope.dart';
import 'di/injection.dart';
import 'router/app_router.dart';

class AetherApp extends StatefulWidget {
  const AetherApp({super.key});

  @override
  State<AetherApp> createState() => _AetherAppState();
}

class _AetherAppState extends State<AetherApp> {
  late final GoRouter _router = buildAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsBloc>.value(
      value: sl<SettingsBloc>(),
      child: BlocBuilder<SettingsBloc, SettingsState>(
      builder: (BuildContext context, SettingsState state) {
        final AppSettings s = state.settings;
        return SettingsScope(
          settings: s,
          child: MaterialApp.router(
            title: 'Aether',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _modeOf(s.theme),
            routerConfig: _router,
          ),
        );
      },
      ),
    );
  }

  static ThemeMode _modeOf(ThemePreference t) {
    if (t == ThemePreference.light) return ThemeMode.light;
    if (t == ThemePreference.system) return ThemeMode.system;
    return ThemeMode.dark;
  }
}
