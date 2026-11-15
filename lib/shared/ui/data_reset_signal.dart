import 'package:flutter/foundation.dart';

/// Fired by "Clear Cache & Reset Datafeed" so every screen reloads from the
/// data source instead of waiting for its next refresh.
class DataResetSignal extends ChangeNotifier {
  void fire() => notifyListeners();
}
