import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/ordnance_tokens.dart';
import '../i18n.dart';
import '../location_flow.dart';
import '../screens/settings_screen.dart';
import '../screens/weather_screen.dart';
import '../tools_units.dart';
import '../weather_api.dart';
import 'ordnance_buttons.dart';

/// Body inset for a screen whose bar is drawn behind the content.
EdgeInsets ordnanceListPadding(
  BuildContext context, {
  required bool root,
  double left = 20,
  double right = 20,
  double bottom = 24,
  double extraTop = 12,
}) {
  final bar = root ? kOrdnanceRootBar : kToolbarHeight;
  final top = MediaQuery.paddingOf(context).top + bar + extraTop;
  return EdgeInsets.fromLTRB(left, top, right, bottom);
}

class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.78),
            border: Border(
              bottom: BorderSide(
                color: dark
                    ? scheme.secondary.withValues(alpha: 0.28)
                    : scheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherChip extends StatefulWidget {
  const _WeatherChip();

  @override
  State<_WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<_WeatherChip> {
  WeatherData? _w;
  bool _loading = false;
  bool _failed = false;

  IconData _conditionIcon(WeatherData w) {
    final p = w.precipProb;
    if (p != null && p >= 50) return Icons.umbrella_outlined;
    if (p != null && p >= 20) return Icons.wb_cloudy_outlined;
    return Icons.wb_sunny_outlined;
  }

  Future<bool> _load() async {
    if (_loading) return _w != null;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final ok = await ensureLocationPermission(context);
      if (!mounted) return false;
      if (!ok) {
        setState(() => _failed = true);
        return false;
      }
      final pos = await fetchCurrentFix();
      if (!mounted) return false;
      if (pos.value == null) {
        setState(() => _failed = true);
        return false;
      }
      final w = await fetchWeather(pos.value!.latitude, pos.value!.longitude);
      if (!mounted) return false;
      setState(() => _w = w);
      return true;
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onTap() async {
    if (_loading) return;
    if (_w != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherScreen()),
      );
      return;
    }
    final ok = await _load();
    if (!mounted) return;
    if (ok) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WeatherScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final w = _w;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outline),
        ),
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(12),
          child: Tooltip(
            message: tr('weather'),
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onSurface,
                        ),
                      )
                    else
                      Icon(
                        w != null
                            ? _conditionIcon(w)
                            : Icons.cloud_outlined,
                        size: 18,
                        color: scheme.onSurface
                            .withValues(alpha: _failed ? 0.45 : 1),
                      ),
                    const SizedBox(width: 6),
                    if (w != null && w.temp != null)
                      ValueListenableBuilder<Map<String, String>>(
                        valueListenable: unitPrefsNotifier,
                        builder: (_, __, ___) => Text(
                          fmtTemp(w.temp!),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      )
                    else if (!_loading)
                      Text(
                        tr('weather'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onSurface
                                  .withValues(alpha: _failed ? 0.45 : 1),
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Root tab bar. Large section title, frosted, with weather and settings.
class OrdnanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSettingsButton;
  final bool showWeather;
  final List<Widget> actions;

  const OrdnanceAppBar({
    super.key,
    this.title = 'Ordnance',
    this.showSettingsButton = true,
    this.showWeather = false,
    this.actions = const [],
  });

  @override
  Size get preferredSize => const Size.fromHeight(kOrdnanceRootBar);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: kOrdnanceRootBar,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: const _GlassBackground(),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDNANCE',
            style: text.labelSmall?.copyWith(
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: scheme.secondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: text.headlineMedium?.copyWith(fontSize: 24),
            ),
          ),
        ],
      ),
      actions: [
        ...actions,
        if (showWeather) const _WeatherChip(),
        if (showSettingsButton)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppIconButton(
              tooltip: tr('settings_title'),
              icon: Icons.settings_outlined,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
      ],
    );
  }
}

/// Subpage bar. Shows [title], not the app name, plus the system back arrow.
class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const SubPageAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: scheme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      flexibleSpace: const _GlassBackground(),
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
