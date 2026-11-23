import 'package:flutter/material.dart';

/// Spacing, radii, elevation, and motion for every Ordnance surface.
/// Screens read these instead of inventing their own numbers.
abstract final class OrdnanceSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class OrdnanceRadius {
  static const double control = 12;
  static const double card = 16;
  static const double sheet = 20;
  static const double icon = 12;
  static const double pill = 999;

  static const BorderRadius controlAll =
      BorderRadius.all(Radius.circular(control));
  static const BorderRadius cardAll =
      BorderRadius.all(Radius.circular(card));
  static const BorderRadius sheetTop = BorderRadius.vertical(
      top: Radius.circular(sheet));
}

abstract final class OrdnanceMotion {
  static const Duration press = Duration(milliseconds: 120);
  static const Duration fadeThrough = Duration(milliseconds: 280);
  static const Duration sharedAxis = Duration(milliseconds: 320);
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

/// Brass used where a widget cannot reach [ColorScheme] (const paints,
/// chart marks). Buttons follow the live accent instead.
const Color ordnanceSignal = Color(0xFFC6A36A);

const Color ordnanceCanvasDark = Color(0xFF07080A);
const Color ordnanceCanvasLight = Color(0xFFF4F5F7);

/// Root tab bar is taller than a subpage bar so the section title can sit
/// at a large-title size without a second heading in the body.
const double kOrdnanceRootBar = 78;
