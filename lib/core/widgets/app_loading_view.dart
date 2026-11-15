import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Generic loading state (spinner + optional message).
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: p.primary,
            ),
          ),
          if (message != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              message!,
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
