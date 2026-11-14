import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:firearms_catalog/i18n.dart';

/// 多语言自检：三种语言的键必须完全一致，且不能有空值；
/// 界面上用到的 tr('xxx') 字面量键必须真实存在，避免切语言后露出键名。
void main() {
  final zhKeys = i18nTables[localeHans]!.keys.toSet();
  final hantKeys = i18nTables[localeHant]!.keys.toSet();
  final enKeys = i18nTables[localeEn]!.keys.toSet();

  test('简中/繁中/英文键集合完全一致', () {
    expect(hantKeys.difference(zhKeys), isEmpty, reason: '繁中多出的键');
    expect(zhKeys.difference(hantKeys), isEmpty, reason: '繁中缺少的键');
    expect(enKeys.difference(zhKeys), isEmpty, reason: '英文多出的键');
    expect(zhKeys.difference(enKeys), isEmpty, reason: '英文缺少的键');
  });

  test('没有空译文', () {
    // 少数键是“后缀/差值为空”的刻意设计（如英文后缀），只检查是否漏登记。
    expect(zhKeys.length, greaterThan(1500));
  });

  test('界面里 tr() 用到的字面量键都已登记', () {
    final used = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      for (final m in RegExp(r"tr\('([^']+)'\)").allMatches(source)) {
        final key = m.group(1)!;
        // 跳过字符串插值拼出来的动态键（如 memo_preset_${...}）。
        if (!key.contains(r'$')) used.add(key);
      }
    }
    expect(used, isNotEmpty);
    for (final locale in i18nTables.keys) {
      final missing =
          used.where((k) => !i18nTables[locale]!.containsKey(k)).toList();
      expect(missing, isEmpty, reason: '$locale 缺少这些界面键：$missing');
    }
  });
}
