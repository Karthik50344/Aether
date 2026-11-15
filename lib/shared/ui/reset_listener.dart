import 'package:flutter/widgets.dart';

import 'data_reset_signal.dart';

/// Calls [onReset] whenever [signal] fires ("Clear cache & reset datafeed").
class ResetListener extends StatefulWidget {
  const ResetListener({
    required this.signal,
    required this.onReset,
    required this.child,
    super.key,
  });
  final DataResetSignal signal;
  final void Function(BuildContext context) onReset;
  final Widget child;

  @override
  State<ResetListener> createState() => _ResetListenerState();
}

class _ResetListenerState extends State<ResetListener> {
  @override
  void initState() {
    super.initState();
    widget.signal.addListener(_fire);
  }

  void _fire() {
    if (mounted) widget.onReset(context);
  }

  @override
  void dispose() {
    widget.signal.removeListener(_fire);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
