import 'package:shared_preferences/shared_preferences.dart';

/// Tiny persistence abstraction so repositories do not depend on a plugin
/// (tests use [InMemoryStore]; the app uses [SharedPrefsStore]).
abstract interface class KeyValueStore {
  Future<List<String>?> readStringList(String key);
  Future<void> writeStringList(String key, List<String> value);
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<bool?> readBool(String key);
  Future<void> writeBool(String key, bool value);
  Future<void> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  @override
  Future<List<String>?> readStringList(String key) async =>
      _prefs.getStringList(key);
  @override
  Future<void> writeStringList(String key, List<String> value) async {
    await _prefs.setStringList(key, value);
  }

  @override
  Future<String?> readString(String key) async => _prefs.getString(key);
  @override
  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<bool?> readBool(String key) async => _prefs.getBool(key);
  @override
  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

class InMemoryStore implements KeyValueStore {
  final Map<String, Object> _data = <String, Object>{};

  @override
  Future<List<String>?> readStringList(String key) async {
    final Object? v = _data[key];
    return v is List<String> ? List<String>.of(v) : null;
  }

  @override
  Future<void> writeStringList(String key, List<String> value) async {
    _data[key] = List<String>.of(value);
  }

  @override
  Future<String?> readString(String key) async {
    final Object? v = _data[key];
    return v is String ? v : null;
  }

  @override
  Future<void> writeString(String key, String value) async => _data[key] = value;

  @override
  Future<bool?> readBool(String key) async {
    final Object? v = _data[key];
    return v is bool ? v : null;
  }

  @override
  Future<void> writeBool(String key, bool value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}
