import 'package:equatable/equatable.dart';

import '../../domain/entities/app_settings.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.settings = const AppSettings(),
    this.persistFailed = false,
  });

  final AppSettings settings;

  /// The last change is applied but could not be written to storage.
  final bool persistFailed;

  @override
  List<Object?> get props => <Object?>[settings, persistFailed];
}
