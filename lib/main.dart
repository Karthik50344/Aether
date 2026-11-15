import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/injection.dart';
import 'core/info/app_info.dart';
import 'core/storage/key_value_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final PackageInfo pkg = await PackageInfo.fromPlatform();
  await configureDependencies(
    store: SharedPrefsStore(prefs),
    appInfo: AppInfo(
      name: pkg.appName,
      version: pkg.version,
      buildNumber: pkg.buildNumber,
    ),
  );
  runApp(const AetherApp());
}
