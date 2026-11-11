import 'dart:ui';
import 'package:flutter/material.dart';
import '../i18n.dart';
import '../location_flow.dart';
import '../screens/settings_screen.dart';
import '../screens/weather_screen.dart';
import '../tools_units.dart';
import '../weather_api.dart';

/// 毛玻璃底：半透明底色 + 模糊（底部细线已按要求去掉）。
/// 主 Tab 页与设置页用 extendBodyBehindAppBar 让内容从栏下滚动而过，
/// 模糊效果才真实可见；其余子页正常布局，栏本身仍是半透明毛玻璃样式。
class _GlassBackground extends StatelessWidget {
  const _GlassBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = dark
        ? const Color(0xFF000000).withValues(alpha: 0.72)
        : const Color(0xFFF7F2E9).withValues(alpha: 0.72);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(color: tint),
      ),
    );
  }
}

/// 顶栏天气小芯片（替代首页天气长条）：条件图标 + 温度，40px 高胶囊，
/// 与右侧齿轮圆形按钮同款底色/边框/阴影。只在点按时才请求定位并
/// 拉取天气，构建时不做任何定位或网络请求。
class _WeatherChip extends StatefulWidget {
  const _WeatherChip();

  @override
  State<_WeatherChip> createState() => _WeatherChipState();
}

class _WeatherChipState extends State<_WeatherChip> {
  WeatherData? _w;
  bool _loading = false;
  bool _failed = false;

  /// 天气状况图标：按降水概率推断（天气接口只给实况数值，无天气码，
  /// 不做雪/雷等细分推断）。与天气页展示的降水概率口径一致。
  IconData _conditionIcon(WeatherData w) {
    final p = w.precipProb;
    if (p != null && p >= 50) return Icons.umbrella;
    if (p != null && p >= 20) return Icons.wb_cloudy;
    return Icons.wb_sunny_outlined;
  }

  /// 与旧首页天气条同款流程：授权 → 取一次 GPS → 拉 Open-Meteo。
  /// 返回 true 表示已拿到数据；失败时置 _failed，不弹任何提示。
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final chipBg = dark ? const Color(0xFF0D0D0D) : Colors.white;
    final w = _w;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _onTap,
        child: Tooltip(
          message: tr('weather'),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: chipBg,
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ink,
                    ),
                  )
                else if (w != null)
                  Icon(_conditionIcon(w), size: 18, color: ink)
                else
                  Icon(
                    Icons.cloud_outlined,
                    size: 18,
                    color: ink.withValues(alpha: _failed ? 0.45 : 0.8),
                  ),
                const SizedBox(width: 4),
                if (w != null && w.temp != null)
                  ValueListenableBuilder<Map<String, String>>(
                    valueListenable: unitPrefsNotifier,
                    builder: (_, __, ___) => Text(
                      fmtTemp(w.temp!),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                  )
                else if (!_loading)
                  Text(
                    tr('weather'),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ink.withValues(alpha: _failed ? 0.45 : 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 主 Tab 顶栏（毛玻璃）：应用名靠左，右上角齿轮圆形设置按钮。
/// 只在首页四个主页面显示；子页面一律用 SubPageAppBar，不再出现应用名与齿轮。
class OrdnanceAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// 设置页本身不再放齿轮按钮，避免重复进设置页。
  final bool showSettingsButton;
  const OrdnanceAppBar({super.key, this.showSettingsButton = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final circleBg = dark ? const Color(0xFF0D0D0D) : Colors.white;
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const _GlassBackground(),
      title: Text(
        "Ordnance",
        style: TextStyle(
          // 字标随全 App 统一走 Manrope。
          fontFamily: 'Manrope',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: ink,
        ),
      ),
      actions: [
        const _WeatherChip(),
        if (showSettingsButton)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.settings_rounded, size: 22, color: ink),
            ),
          ),
        ),
      ],
    );
  }
}

/// 子页顶栏（毛玻璃）：只显示本页标题 + 系统返回箭头，不显示 App 名与齿轮。
/// 子页面显示优先：全局栏与正文返回行重复的问题，用这一个栏统一解决。
class SubPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const SubPageAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: const _GlassBackground(),
      title: Text(
        "Ordnance",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: ink,
        ),
      ),
    );
  }
}
