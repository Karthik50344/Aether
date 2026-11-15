import 'package:equatable/equatable.dart';

/// Theme choice (typed constants, not an enum).
/// Dark is the Figma design; light is DERIVED from the same tokens.
class ThemePreference extends Equatable {
  const ThemePreference._(this.id, this.label);
  final String id;
  final String label;

  static const ThemePreference system = ThemePreference._('system', 'System');
  static const ThemePreference dark = ThemePreference._('dark', 'Dark');
  static const ThemePreference light = ThemePreference._('light', 'Light');
  static const List<ThemePreference> all = <ThemePreference>[system, dark, light];

  static const ThemePreference defaultValue = dark;

  static ThemePreference fromId(String? id) {
    for (final ThemePreference t in all) {
      if (t.id == id) return t;
    }
    return defaultValue;
  }

  @override
  List<Object?> get props => <Object?>[id];
}
