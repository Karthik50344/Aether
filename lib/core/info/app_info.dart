import 'package:equatable/equatable.dart';

/// Real app metadata (from package_info_plus in `main`, a placeholder in tests).
class AppInfo extends Equatable {
  const AppInfo({
    this.name = 'Aether',
    this.version = '1.0.0',
    this.buildNumber = '1',
  });

  final String name;
  final String version;
  final String buildNumber;

  String get full => '$version+$buildNumber';

  @override
  List<Object?> get props => <Object?>[name, version, buildNumber];
}

/// How often screens poll the REST API (null = disabled, e.g. in tests).
class RefreshPolicy extends Equatable {
  const RefreshPolicy(this.interval);
  final Duration? interval;

  String get label =>
      interval == null ? 'Manual (pull to refresh)' : 'Every ${interval!.inSeconds} s';

  @override
  List<Object?> get props => <Object?>[interval];
}
