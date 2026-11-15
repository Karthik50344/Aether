import 'package:equatable/equatable.dart';

/// Load status (typed constants, not an enum).
class LoadStatus extends Equatable {
  const LoadStatus._(this.id);
  final String id;

  static const LoadStatus initial = LoadStatus._('initial');
  static const LoadStatus loading = LoadStatus._('loading');
  static const LoadStatus success = LoadStatus._('success');
  static const LoadStatus failure = LoadStatus._('failure');

  @override
  List<Object?> get props => <Object?>[id];
}
