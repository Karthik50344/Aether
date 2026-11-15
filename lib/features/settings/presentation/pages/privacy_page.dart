import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_typography.dart';

/// In-app privacy summary (what the app stores and what it contacts).
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const List<(String, String)> _items = <(String, String)>[
    ('Research only',
        'Aether is a market research tool. It is not an exchange, holds no funds and places no orders.'),
    ('No account',
        'There is no sign-up or login. Aether never asks for API keys, wallets or personal data.'),
    ('Stored on this device',
        'Your watchlist and preferences (theme, default quote asset, default timeframe, compact metrics) are saved locally and never uploaded.'),
    ('Network access',
        'When the data source is "remote", the app calls only Binance public market-data endpoints (prices, candles, order-book depth, recent trades). With "sample data" it makes no network calls.'),
    ('Scope of the numbers',
        'All figures describe Binance Spot pairs only. They are not global market statistics and are not investment advice.'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppPalette p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          for (final (String t, String b) in _items) ...<Widget>[
            Text(t,
                style: AppTypography.sectionTitle.copyWith(color: p.textPrimary),),
            const SizedBox(height: 4),
            Text(b, style: AppTypography.body.copyWith(color: p.textSecondary)),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}
