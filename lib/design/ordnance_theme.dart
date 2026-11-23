import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../haptics.dart';
import '../widgets/page_transitions.dart';
import 'ordnance_tokens.dart';

/// Ink splash that also ticks the shared haptic, so every Material control
/// (buttons, list tiles, chips) feels the same. [tapHaptic] debounces.
class HapticInkFactory extends InteractiveInkFeatureFactory {
  const HapticInkFactory(this.inner);
  final InteractiveInkFeatureFactory inner;

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    tapHaptic();
    return inner.create(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

Color _onFill(Color fill) => fill.computeLuminance() > 0.55
    ? const Color(0xFF121418)
    : const Color(0xFFF7F7F5);

/// Accent that stays readable on the scaffold of [brightness].
Color ordnancePrimary(Brightness brightness, Color accent) {
  final hsl = HSLColor.fromColor(accent);
  if (brightness == Brightness.dark) {
    final lightness = hsl.lightness < 0.58 ? 0.62 : hsl.lightness;
    final saturation = (hsl.saturation < 0.45 ? 0.48 : hsl.saturation)
        .clamp(0.42, 0.78);
    return hsl.withLightness(lightness).withSaturation(saturation).toColor();
  }
  if (hsl.lightness > 0.46) return hsl.withLightness(0.36).toColor();
  return accent;
}

ThemeData buildOrdnanceTheme(Brightness brightness, Color accent) {
  final dark = brightness == Brightness.dark;
  final primary = ordnancePrimary(brightness, accent);
  final onPrimary = _onFill(primary);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: onPrimary,
    secondary: dark ? const Color(0xFF8AA0AE) : const Color(0xFF3E5563),
    onSecondary: dark ? const Color(0xFF0C0E12) : const Color(0xFFF7F8FA),
    error: const Color(0xFFE15D5D),
    onError: const Color(0xFF1A0A0A),
    surface: dark ? const Color(0xFF101216) : const Color(0xFFFFFFFF),
    onSurface: dark ? const Color(0xFFF2F3F5) : const Color(0xFF14161A),
    surfaceContainerLowest:
        dark ? ordnanceCanvasDark : ordnanceCanvasLight,
    surfaceContainerLow:
        dark ? const Color(0xFF0C0E12) : const Color(0xFFF7F8FA),
    surfaceContainer:
        dark ? const Color(0xFF14171C) : const Color(0xFFF7F8FA),
    surfaceContainerHigh:
        dark ? const Color(0xFF1C2026) : const Color(0xFFEEF0F3),
    surfaceContainerHighest:
        dark ? const Color(0xFF242932) : const Color(0xFFE6E9EE),
    onSurfaceVariant:
        dark ? const Color(0xFF9AA1AD) : const Color(0xFF5E6670),
    outline: dark ? const Color(0xFF2C313A) : const Color(0xFFD5DAE1),
    outlineVariant:
        dark ? const Color(0xFF23272F) : const Color(0xFFE4E7EC),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xCC000000),
    inverseSurface: dark ? const Color(0xFFF2F3F5) : const Color(0xFF14161A),
    onInverseSurface: dark ? const Color(0xFF14161A) : const Color(0xFFF2F3F5),
    inversePrimary: accent,
  );

  final radius = RoundedRectangleBorder(borderRadius: OrdnanceRadius.controlAll);
  final label = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  ButtonStyle filled() => FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: radius,
        textStyle: label,
        elevation: 0,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.surfaceContainerHighest,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return scheme.onPrimary.withValues(alpha: 0.12);
          }
          if (states.contains(WidgetState.hovered)) {
            return scheme.onPrimary.withValues(alpha: 0.06);
          }
          return null;
        }),
      );

  final outlined = OutlinedButton.styleFrom(
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    shape: radius,
    textStyle: label,
    foregroundColor: scheme.onSurface,
    backgroundColor: Colors.transparent,
    side: BorderSide(color: scheme.outline),
  ).copyWith(
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return scheme.primary.withValues(alpha: 0.12);
      }
      return null;
    }),
  );

  final text = TextButton.styleFrom(
    minimumSize: const Size(48, 48),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    shape: radius,
    textStyle: label.copyWith(fontWeight: FontWeight.w600),
    foregroundColor: scheme.primary,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  final icon = IconButton.styleFrom(
    minimumSize: const Size(40, 40),
    fixedSize: const Size(40, 40),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: scheme.onSurface,
    shape: radius,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    canvasColor: scheme.surfaceContainerLowest,
    splashFactory: const HapticInkFactory(InkRipple.splashFactory),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: SharedAxisPageTransitionsBuilder(),
        TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(),
        TargetPlatform.macOS: SharedAxisPageTransitionsBuilder(),
        TargetPlatform.windows: SharedAxisPageTransitionsBuilder(),
        TargetPlatform.linux: SharedAxisPageTransitionsBuilder(),
        TargetPlatform.fuchsia: SharedAxisPageTransitionsBuilder(),
      },
    ),
    textTheme: _text(scheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: _text(scheme).titleLarge,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: OrdnanceRadius.cardAll,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: OrdnanceRadius.cardAll),
      titleTextStyle: _text(scheme).titleLarge,
      contentTextStyle: _text(scheme).bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      modalBackgroundColor: scheme.surfaceContainerHigh,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(borderRadius: OrdnanceRadius.sheetTop),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: OrdnanceRadius.controlAll,
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: OrdnanceRadius.controlAll,
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: OrdnanceRadius.controlAll,
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: filled()),
    elevatedButtonTheme: ElevatedButtonThemeData(style: filled()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlined),
    textButtonTheme: TextButtonThemeData(style: text),
    iconButtonTheme: IconButtonThemeData(style: icon),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 2,
      highlightElevation: 2,
      shape: RoundedRectangleBorder(borderRadius: OrdnanceRadius.cardAll),
      sizeConstraints: const BoxConstraints.tightFor(width: 56, height: 56),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainer,
      selectedColor: scheme.primary.withValues(alpha: 0.18),
      disabledColor: scheme.surfaceContainer,
      side: BorderSide(color: scheme.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      showCheckmark: false,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: OrdnanceRadius.cardAll),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(color: scheme.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: OrdnanceRadius.controlAll),
    ),
  );
}

const kOrdnanceCjkFallback = <String>[
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'PingFang SC',
  'Heiti SC',
  'Microsoft YaHei',
  'sans-serif',
];

TextTheme _text(ColorScheme scheme) {
  const family = 'Inter';
  TextStyle s(double size, FontWeight weight, double height, double tracking,
      {bool tabular = false}) {
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: kOrdnanceCjkFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking,
      color: scheme.onSurface,
      fontFeatures:
          tabular ? const [FontFeature.tabularFigures()] : null,
    );
  }

  return TextTheme(
    displaySmall: s(32, FontWeight.w600, 1.15, -0.6, tabular: true),
    headlineMedium: s(26, FontWeight.w600, 1.2, -0.4),
    titleLarge: s(20, FontWeight.w600, 1.25, -0.2),
    titleMedium: s(16, FontWeight.w600, 1.3, 0),
    titleSmall: s(14, FontWeight.w600, 1.3, 0.1),
    bodyLarge: s(16, FontWeight.w400, 1.4, 0),
    bodyMedium: s(14, FontWeight.w400, 1.4, 0),
    bodySmall: s(12, FontWeight.w400, 1.35, 0.1)
        .copyWith(color: scheme.onSurfaceVariant),
    labelLarge: s(14, FontWeight.w600, 1.2, 0.1),
    labelMedium: s(12, FontWeight.w600, 1.2, 0.4),
    labelSmall: s(11, FontWeight.w500, 1.2, 0.4)
        .copyWith(color: scheme.onSurfaceVariant),
  );
}
