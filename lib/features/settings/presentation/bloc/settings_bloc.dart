import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/settings_usecases.dart';
import 'settings_event.dart';
import 'settings_state.dart';

export 'settings_event.dart';
export 'settings_state.dart';

/// App-wide preferences. A change is applied to the UI immediately and then
/// persisted; a storage failure never reverts what the user sees.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required SaveSettings saveSettings,
    AppSettings initial = const AppSettings(),
  })  : _save = saveSettings,
        super(SettingsState(settings: initial)) {
    on<ThemeChanged>((e, emit) => _apply(emit, state.settings.copyWith(theme: e.theme)));
    on<DefaultQuoteChanged>(
        (e, emit) => _apply(emit, state.settings.copyWith(defaultQuote: e.quote)));
    on<DefaultPeriodChanged>(
        (e, emit) => _apply(emit, state.settings.copyWith(defaultPeriod: e.period)));
    on<CompactMetricsChanged>(
        (e, emit) => _apply(emit, state.settings.copyWith(compactMetrics: e.compact)));
  }

  final SaveSettings _save;

  Future<void> _apply(Emitter<SettingsState> emit, AppSettings next) async {
    if (next == state.settings) return;
    emit(SettingsState(settings: next));
    try {
      await _save(next);
    } catch (_) {
      emit(SettingsState(settings: next, persistFailed: true));
    }
  }
}
