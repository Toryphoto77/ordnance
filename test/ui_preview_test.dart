import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firearms_catalog/design/ordnance_theme.dart';
import 'package:firearms_catalog/main.dart';
import 'package:firearms_catalog/screens/ammo_hub_screen.dart';
import 'package:firearms_catalog/screens/catalog_screen.dart';
import 'package:firearms_catalog/screens/gun_cabinet_screen.dart';
import 'package:firearms_catalog/screens/range_home_screen.dart';
import 'package:firearms_catalog/screens/settings_screen.dart';
import 'package:firearms_catalog/screens/tools_screen.dart';
import 'package:firearms_catalog/theme_accent.dart';

/// Writes PNGs when ORDNANCE_SHOTS is set. Each screen is its own test so
/// one layout problem cannot block the rest. Errors are recorded and not
/// rethrown, because the test binding's handler can deadlock a frame.
void main() {
  AutomatedTestWidgetsFlutterBinding.ensureInitialized();

  final shots = Platform.environment['ORDNANCE_SHOTS'];
  if (shots == null || shots.isEmpty) {
    test('screen captures are opt-in', () {});
    return;
  }

  setUpAll(() async {
    // Widget tests do not load the engine icon font or pubspec fonts.
    // Icons.* are MaterialIcons private-use codepoints, so without this
    // file they paint as empty squares. The app itself includes the font
    // via uses-material-design: true. Inter is the UI face.
    final inter = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await inter.load();
    await _loadFileFont(
      'MaterialIcons',
      _materialIconsFile(),
    );
  });

  final cases = <String, Widget Function()>{
    'shell': () => const HomePage(),
    'range': () => const RangeHomeScreen(),
    'ammo': () => const AmmoHubScreen(),
    'directory': () => const CatalogScreen(),
    'tools': () => const ToolsScreen(),
    'settings': () => const SettingsScreen(),
    'armory': () => const GunCabinetScreen(),
  };

  for (final entry in cases.entries) {
    testWidgets(entry.key, (tester) async {
      Directory(shots).createSync(recursive: true);
      FlutterError.onError = (details) {
        File('$shots/errors.txt').writeAsStringSync(
          '${entry.key}: ${details.exceptionAsString()}\n',
          mode: FileMode.append,
        );
      };
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final messenger = tester.binding.defaultBinaryMessenger;
      for (final name in const [
        'gunsmap/prefs',
        'gunsmap/system',
        'gunsmap/share',
      ]) {
        messenger.setMockMethodCallHandler(
            MethodChannel(name), (call) async => null);
      }
      final sample = Platform.environment['ORDNANCE_SAMPLE'] == '1';
      messenger.setMockMethodCallHandler(const MethodChannel('gunsmap/prefs'),
          (call) async {
        if (!sample || call.method != 'getString') return null;
        final key = (call.arguments as Map?)?['key'];
        if (key == 'range_sessions_v1') return _sampleSessions();
        return _samplePrefs[key];
      });
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildOrdnanceTheme(Brightness.light, defaultAccent),
        darkTheme: buildOrdnanceTheme(Brightness.dark, defaultAccent),
        themeMode: ThemeMode.dark,
        home: entry.value(),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first);
      final image = boundary.toImageSync(pixelRatio: 1);
      final bytes = await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.png));
      final prefix = sample ? 'sample_' : '';
      File('$shots/$prefix${entry.key}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    }, timeout: const Timeout(Duration(seconds: 20)));
  }
}

/// Fixture rows for screenshot captures only. The app never ships these.
final _samplePrefs = <String, String>{
  'gun_profiles_v1':
      '[{"gunName":"Sample rifle","nickname":"Sample","rounds":640,"maintEveryRounds":500,"maintEveryDays":90}]',
  'ammo_inventory_v1':
      '[{"caliber":"5.56","name":"Sample 55gr","quantity":180,"lowAt":40},{"caliber":"9mm","name":"Sample 115gr","quantity":36,"lowAt":50},{"caliber":".308","name":"Sample match","quantity":80,"lowAt":20}]',
};

String _sampleSessions() {
  final now = DateTime.now();
  int ms(int daysAgo) =>
      now.subtract(Duration(days: daysAgo)).millisecondsSinceEpoch;
  return '['
      '{"id":"s1","dateMs":${ms(1)},"gunName":"Sample rifle","place":"Sample range","distance":"100","drill":"Slow fire","target":"Sample","rounds":20,"score":"98","ammoName":"Sample 55gr","lot":"S","notes":""},'
      '{"id":"s2","dateMs":${ms(6)},"gunName":"Sample rifle","place":"Sample range","distance":"200","drill":"Slow fire","target":"Sample","rounds":40,"score":"95","ammoName":"Sample 55gr","lot":"S","notes":""},'
      '{"id":"s3","dateMs":${ms(12)},"gunName":"Sample rifle","place":"Sample range","distance":"100","drill":"Rapid","target":"Sample","rounds":30,"score":"91","ammoName":"Sample 55gr","lot":"S","notes":""}'
      ']';
}

File _materialIconsFile() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) {
    throw StateError('FLUTTER_ROOT is unset; cannot load MaterialIcons');
  }
  final file = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (!file.existsSync()) {
    throw StateError('MaterialIcons font missing at ${file.path}');
  }
  return file;
}

Future<void> _loadFileFont(String family, File file) async {
  final bytes = await file.readAsBytes();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  final loader = FontLoader(family)..addFont(Future<ByteData>.value(data));
  await loader.load();
}
