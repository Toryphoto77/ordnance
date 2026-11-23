import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/ordnance_tokens.dart';

/// True when the platform asks for motion. Animations collapse to their
/// end state so a reduced-motion session stays still.
bool ordnanceMotionOn(BuildContext context) =>
    !MediaQuery.disableAnimationsOf(context);

Duration ordnanceDur(BuildContext context, Duration duration) =>
    ordnanceMotionOn(context) ? duration : Duration.zero;

/// Layered surface: gradient, hairline, and a soft accent glow.
class HudPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  const HudPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: OrdnanceRadius.cardAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh,
            scheme.surfaceContainer,
          ],
        ),
        border: Border.all(
          color: glow
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant,
        ),
        boxShadow: [
          if (dark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          if (glow)
            BoxShadow(
              color: scheme.primary.withValues(alpha: dark ? 0.22 : 0.12),
              blurRadius: 22,
              spreadRadius: -4,
            ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
            color: scheme.secondary,
          ),
    );
  }
}

class FigureText extends StatelessWidget {
  final String value;
  final double size;
  const FigureText(this.value, {super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final end = num.tryParse(value.replaceAll(',', ''));
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: size,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          height: 1.05,
        );
    if (end == null || !ordnanceMotionOn(context)) {
      return Text(value, style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: end.toDouble()),
      duration: ordnanceDur(context, const Duration(milliseconds: 640)),
      curve: OrdnanceMotion.emphasized,
      builder: (_, v, __) => Text(
        end is int ? v.round().toString() : v.toStringAsFixed(0),
        style: style,
      ),
    );
  }
}

class PressScale extends StatefulWidget {
  final Widget child;
  const PressScale({super.key, required this.child});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final on = ordnanceMotionOn(context);
    return Listener(
      onPointerDown: (_) {
        if (on) setState(() => _down = true);
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: ordnanceDur(context, OrdnanceMotion.press),
        curve: OrdnanceMotion.enter,
        child: widget.child,
      ),
    );
  }
}

class StaggerIn extends StatelessWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!ordnanceMotionOn(context)) return child;
    final delay = index * 36;
    final total = 320 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class ProgressRing extends StatelessWidget {
  final double value;
  final String center;
  final String caption;
  final double size;
  const ProgressRing({
    super.key,
    required this.value,
    required this.center,
    required this.caption,
    this.size = 92,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size + 18,
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: v),
              duration: ordnanceDur(context, const Duration(milliseconds: 700)),
              curve: OrdnanceMotion.emphasized,
              builder: (_, t, __) => CustomPaint(
                painter: _RingPainter(
                  t: t,
                  color: Theme.of(context).colorScheme.primary,
                  track: Theme.of(context).colorScheme.outline,
                ),
                child: Center(child: FigureText(center, size: 20)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Eyebrow(caption),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  final Color track;
  _RingPainter({required this.t, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - 5;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = track;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(c, r, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      arc,
    );
    // HUD ticks.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = color.withValues(alpha: 0.45);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p1 = c + Offset(math.cos(a), math.sin(a)) * (r + 2);
      final p2 = c + Offset(math.cos(a), math.sin(a)) * (r + 6);
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.t != t || old.color != color || old.track != track;
}

class MiniBars extends StatelessWidget {
  final List<(String, int)> rows;
  const MiniBars({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final maxV = rows.map((e) => e.$2).reduce(math.max).clamp(1, 1 << 30);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final row in rows.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(
                    row.$1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: row.$2 / maxV),
                      duration: ordnanceDur(
                          context, const Duration(milliseconds: 600)),
                      curve: OrdnanceMotion.emphasized,
                      builder: (_, t, __) => LinearProgressIndicator(
                        value: t,
                        minHeight: 6,
                        backgroundColor: scheme.outline.withValues(alpha: 0.45),
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${row.$2}',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class Sparkline extends StatelessWidget {
  final List<double> values;
  const Sparkline({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparkPainter(
          values: values,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 0.001 ? 1.0 : maxV - minV;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height - ((values[i] - minV) / span) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}

/// Empty state: rings and a grid, no illustration, plus a single action.
class EmptyInstrument extends StatelessWidget {
  final String message;
  final Widget? action;
  const EmptyInstrument({super.key, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return HudPanel(
      child: Column(
        children: [
          SizedBox(
            height: 112,
            width: double.infinity,
            child: CustomPaint(
              painter: _EmptyHudPainter(
                color: scheme.primary,
                line: scheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            action!,
          ],
        ],
      ),
    );
  }
}

class _EmptyHudPainter extends CustomPainter {
  final Color color;
  final Color line;
  _EmptyHudPainter({required this.color, required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final grid = Paint()
      ..color = line.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), grid);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.85);
    canvas.drawCircle(c, 28, ring);
    canvas.drawCircle(c, 16, ring..strokeWidth = 1);
    canvas.drawLine(Offset(c.dx, c.dy - 36), Offset(c.dx, c.dy - 30), ring);
  }

  @override
  bool shouldRepaint(_EmptyHudPainter old) =>
      old.color != color || old.line != line;
}

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Eyebrow(title),
          ),
          HudPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: scheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
