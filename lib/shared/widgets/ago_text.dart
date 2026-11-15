import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters/formatters.dart';

/// "Updated 3s ago" that keeps ticking once per second.
class AgoText extends StatefulWidget {
  const AgoText({
    required this.since,
    required this.style,
    this.prefix = 'Updated ',
    this.now,
    super.key,
  });

  final DateTime? since;
  final TextStyle style;
  final String prefix;
  final DateTime Function()? now;

  @override
  State<AgoText> createState() => _AgoTextState();
}

class _AgoTextState extends State<AgoText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? t = widget.since;
    final String text = t == null
        ? '${widget.prefix}--'
        : '${widget.prefix}${Fmt.ago(t, (widget.now ?? DateTime.now)())}';
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: widget.style);
  }
}
