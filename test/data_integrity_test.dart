import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firearms_catalog/app_version.dart';
import 'package:firearms_catalog/data.dart';

/// 数据与资源自检：图鉴数据、图标资源与版本号是本项目最容易悄悄坏掉的地方，
/// 这里用测试兜住——以后加数据或换资源，跑一遍就知道有没有漏。
void main() {
  group('图鉴数据', () {
    test('枪械数量与品类齐全', () {
      expect(guns.length, greaterThanOrEqualTo(700));
      expect(categories.length, 8);
    });

    test('每支枪的品类都在固定品类里', () {
      final unknown = guns
          .where((g) => !categories.contains(g.category))
          .map((g) => g.name)
          .toList();
      expect(unknown, isEmpty, reason: '出现未知品类：$unknown');
    });

    test('枪名不重复', () {
      final names = guns.map((g) => g.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('配件、口径、名枪数据非空且名称不重复', () {
      expect(accessories, isNotEmpty);
      expect(caliberInfos, isNotEmpty);
      expect(legends, isNotEmpty);
      _expectUniqueNames(accessories.map((a) => a.name));
      _expectUniqueNames(legends.map((l) => l.name));
    });
  });

  group('图片与字体资源', () {
    test('每支有图的枪，图片文件都存在', () {
      final missing = guns
          .map((g) => g.image)
          .whereType<String>()
          .where((p) => !File(p).existsSync())
          .toList();
      expect(missing, isEmpty, reason: '缺失图片：$missing');
    });

    test('应用图标仍在，目录不再依赖品类图', () {
      expect(File('assets/images/app-icon.png').existsSync(), isTrue);
    });

    test('Inter four weights and the OFL license are bundled', () {
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        expect(File('assets/fonts/Inter-$weight.ttf').existsSync(), isTrue,
            reason: 'missing Inter-$weight.ttf');
      }
      expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
    });
  });

  group('版本号', () {
    test('appVersion 与 pubspec.yaml 一致', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final match =
          RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+', multiLine: true)
              .firstMatch(pubspec);
      expect(match, isNotNull, reason: 'pubspec.yaml 里没有找到 version');
      expect(match!.group(1), appVersion);
    });
  });
}

void _expectUniqueNames(Iterable<String> names) {
  final list = names.toList();
  expect(list.toSet().length, list.length);
}
