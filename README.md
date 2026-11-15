# Aether — Binance Spot research app (Flutter)

A cryptocurrency **research** app (not an exchange): explore Binance Spot trading pairs, watch 24h movements, view price charts, keep a watchlist. Built from a Figma design with feature-first Clean Architecture.

> **Status: All 8 phases written written but NOT yet compiled.**
> The authoring environment had no Flutter SDK, so `flutter analyze` / `flutter test` have not been run on this code. Run `tool/verify.sh` (or the steps below) and fix what it reports.
> Mock data is SAMPLE data (`tool/generate_mock_data.py`), not real market data.

## Stack
Flutter · Dart · flutter_bloc (BLoC, no Cubit) · Equatable · GoRouter · get_it · Dio · fl_chart · SharedPreferences · intl · package_info_plus · flutter_test · mocktail.
No code generation. No Dart enums (typed constant classes instead).

## Setup
```
flutter create . --platforms=android,ios     # once: generates android/ and ios/
flutter pub get
tool/verify.sh                               # pub get, dart fix, format, analyze, test
```
Run: `flutter run` (SAMPLE data) · `flutter run --dart-define=DATA_SOURCE=remote` (Binance Spot public REST, no key).
Release APK: `flutter build apk --release --dart-define=DATA_SOURCE=remote`
Android release builds need `<uses-permission android:name="android.permission.INTERNET"/>` in `android/app/src/main/AndroidManifest.xml` (`flutter create` only adds it to the debug manifest). The APK is signed with the debug key until you configure a release keystore.

## Architecture
Feature-first Clean Architecture. Data flow:

`UI -> BLoC -> use cases -> repository contract -> repository impl -> data source (mock JSON | Binance REST)`

```
lib/
  app/        DI (get_it), router (GoRouter), config, root widget
  core/       theme, formatters, errors, network (ApiClient), storage, constants, shared states/widgets
  shared/     cross-feature entities and widgets (TradingPair, shell, header, nav, avatars, sparkline)
  features/
    market/        dashboard (+ the data layer every feature uses)
    explore/       search, filters, sort, market breadth
    coin_details/  chart + indicators, stats, order-book depth, recent trades
    watchlist/     saved pairs, reorder, add/remove
    settings/      preferences, telemetry, privacy
```
- One `MarketDataSource` interface returns API-shaped models; the mock and the Dio source are interchangeable, so joining, caching and entity mapping live once in `MarketRepositoryImpl`.
- Failures are typed (`AppException`); nothing outside the data layer sees Dio.
- Blocs guard against stale responses (sequence numbers), keep sections independent, and poll with an injectable interval (disabled in tests).

## Branding
The mark is an "A" whose crossbar is a rising price line breaking out through the right leg (original design, brand colours from the dark palette).
- Source of truth: `tool/generate_branding.py` -> `assets/branding/` (SVG + PNGs: `icon.png`, `icon_foreground.png` for Android adaptive, `splash.png`, `logo_mark.*`, `logo_rounded.*`).
- In-app: `AetherLogo` (`lib/shared/widgets/aether_logo.dart`) draws the same geometry in code; used in the header and Settings.
- Launcher icon + splash (after `flutter create`): `dart run flutter_launcher_icons` then `dart run flutter_native_splash:create`.
- Set the store/launcher name to "Aether": `android:label="Aether"` in `AndroidManifest.xml` and `CFBundleDisplayName` in `ios/Runner/Info.plist`.

## Design system
Exact tokens from Figma are in `docs/DESIGN_TOKENS.md` and implemented in `lib/core/theme/`.
- **Dark theme:** pixel values from Figma. **Light theme:** derived by us from the same colour roles (Figma has no light design).
- Fonts are bundled (Inter, JetBrains Mono, SIL OFL). Icons are Material icons routed through `lib/core/theme/app_icons.dart` (swap for the Figma SVGs by editing only that file + adding `flutter_svg`).

## Market-data accuracy
Binance Spot data is exchange-specific (BTCUSDT = BTC priced in USDT). The app never presents it as global market data and shows no market cap, supply or global volume. Figma labels that implied otherwise were relabelled ("Binance Spot", "Market Breadth", "24h VWAP", "Taker buy share", "Polling"); sector chips are app-curated. Full list: `docs/PHASE0_SPEC.md` section 9. Mock data is SAMPLE data (`tool/generate_mock_data.py`).

## Data source notes
- Cached: exchangeInfo 1 h, all-symbol tickers 10 s, shared between screens; pull-to-refresh / "Clear Cache & Reset Datafeed" bypass it.
- HTTP 429/418: requests pause for `Retry-After` (default 30 s / 2 min) and the UI shows the wait.
- Polling every 15 s (REST, not WebSocket).

## Tests
`test/` mirrors `lib/`: formatters, repositories, every bloc (mocktail), the Dio client (scripted adapter), and widget tests through a GoRouter with a fake data source. `flutter test`.

## Known limitations
- Never compiled in the authoring environment; expect to fix whatever `flutter analyze` / `flutter test` report on first run.
- No screenshots are included (nothing could be run to capture them).
- No WebSocket streaming, no alerts/notifications, no accounts, no trading - by design.
- Search matches symbols only; sector chips cover a curated list of top assets.
