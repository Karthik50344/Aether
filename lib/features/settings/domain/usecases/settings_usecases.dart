import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

class GetSettings {
  const GetSettings(this._repository);
  final SettingsRepository _repository;
  Future<AppSettings> call() => _repository.load();
}

class SaveSettings {
  const SaveSettings(this._repository);
  final SettingsRepository _repository;
  Future<void> call(AppSettings settings) => _repository.save(settings);
}
