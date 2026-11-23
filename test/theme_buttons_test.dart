import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firearms_catalog/design/ordnance_theme.dart';
import 'package:firearms_catalog/theme_accent.dart';
import 'package:firearms_catalog/widgets/ordnance_buttons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primary, secondary, and text buttons share one control size',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildOrdnanceTheme(Brightness.dark, defaultAccent),
      home: Scaffold(
        body: Column(
          children: [
            AppButton.primary(label: 'Save', onPressed: () {}),
            AppButton.secondary(label: 'Cancel', onPressed: () {}),
            AppButton.text(label: 'More', onPressed: () {}),
            AppIconButton(icon: Icons.settings_outlined, onPressed: () {}),
          ],
        ),
      ),
    ));

    double heightOf(Finder finder) => tester.getSize(finder).height;
    expect(heightOf(find.widgetWithText(FilledButton, 'Save')), 48);
    expect(heightOf(find.widgetWithText(OutlinedButton, 'Cancel')), 48);
    expect(heightOf(find.widgetWithText(TextButton, 'More')), 48);
    expect(tester.getSize(find.byType(AppIconButton)).height, 40);

    final theme = Theme.of(tester.element(find.byType(Scaffold)));
    BorderRadius radiusOf(ButtonStyle? style) {
      final shape = style?.shape?.resolve(<WidgetState>{});
      return (shape as RoundedRectangleBorder).borderRadius
          as BorderRadius;
    }

    final primary = radiusOf(theme.filledButtonTheme.style);
    final secondary = radiusOf(theme.outlinedButtonTheme.style);
    final text = radiusOf(theme.textButtonTheme.style);
    expect(primary.topLeft.x, 12);
    expect(secondary.topLeft.x, primary.topLeft.x);
    expect(text.topLeft.x, primary.topLeft.x);
  });
}
