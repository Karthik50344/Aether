import 'package:flutter/foundation.dart';

/// Lets the header's search button ask the Explore screen to focus its search
/// field - even when that screen has not been built yet (tabs are lazy).
class SearchFocusSignal extends ChangeNotifier {
  bool _pending = false;

  /// True until the Explore screen consumes the request.
  bool get pending => _pending;

  void request() {
    _pending = true;
    notifyListeners();
  }

  /// Returns whether a request was waiting, and clears it.
  bool consume() {
    final bool was = _pending;
    _pending = false;
    return was;
  }
}
