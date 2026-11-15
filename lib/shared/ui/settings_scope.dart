import 'package:flutter/widgets.dart';

import '../../features/settings/domain/entities/app_settings.dart';

/// Exposes the current [AppSettings] to the whole tree without requiring a
/// SettingsBloc in every test: widgets outside a scope get the defaults.
class SettingsScope extends InheritedWidget {
  const SettingsScope({required this.settings, required super.child, super.key});

  final AppSettings settings;

  static AppSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()?.settings ??
      const AppSettings();

  static bool compactOf(BuildContext context) => of(context).compactMetrics;

  @override
  bool updateShouldNotify(SettingsScope old) => settings != old.settings;
}
