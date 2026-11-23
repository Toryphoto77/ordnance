import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_icon.dart';
import 'design/ordnance_theme.dart';
import 'design/ordnance_tokens.dart';
import 'gun_cabinet_data.dart';
import 'theme_accent.dart';
import 'community_store.dart';
import 'haptics.dart';
import 'i18n.dart';
import 'screens/ammo_hub_screen.dart';
import 'screens/catalog_screen.dart';
import 'screens/community_screen.dart';
import 'screens/gun_cabinet_screen.dart';
import 'screens/range_home_screen.dart';
import 'widgets/page_transitions.dart';

/// 主题选择状态：设置页写入，MaterialApp 监听切换。
/// 仅本次打开期间生效，不做持久化。
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 先从本机读回社区数据（带超时兜底，不阻塞启动太久），再进首页。
  await communityStore.init();
  // 2.2.5 枪柜迁移：旧收藏的拥有枪幂等迁入枪柜自有存储（有标记则跳过，
  // 失败不阻塞启动，下次再试；旧收藏数据原样保留）。
  await migrateCabinetFromCollection();
  // 启动图标：固定黑底色，冷启动应用一次；不再跟随主题或平台亮度变化。
  await syncAppIcon();
  // 主题强调色：读回上次选择，读不到则默认铜色。
  await loadAccent();
  runApp(const FirearmsApp());
}

class FirearmsApp extends StatelessWidget {
  const FirearmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (_, mode, __) => ValueListenableBuilder<String>(
        valueListenable: localeNotifier,
        builder: (_, ___, ____) => ValueListenableBuilder<Color>(
          valueListenable: accentNotifier,
          builder: (_, accent, _____) => MaterialApp(
            title: 'Ordnance',
            themeMode: mode,
            theme: buildOrdnanceTheme(Brightness.light, accent),
            darkTheme: buildOrdnanceTheme(Brightness.dark, accent),
            home: const HomePage(),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _tabs = [
    (Icons.gps_fixed_outlined, Icons.gps_fixed, 'tab_range'),
    (Icons.shield_outlined, Icons.shield, 'tab_armory'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'tab_ammo'),
    (Icons.menu_book_outlined, Icons.menu_book, 'tab_catalog'),
    (Icons.forum_outlined, Icons.forum, 'tab_community'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final pages = [
      RangeHomeScreen(),
      GunCabinetScreen(),
      AmmoHubScreen(),
      CatalogScreen(),
      CommunityScreen(),
    ];
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: theme.scaffoldBackgroundColor,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ),
        child: Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              FadeThroughSwitcher(
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: pages[_index],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FrostedNavBar(
                      index: _index,
                      onTap: (i) {
                        if (i == _index) return;
                        tapHaptic();
                        setState(() => _index = i);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrostedNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _FrostedNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (dark ? const Color(0xFF0C0E12) : Colors.white)
                .withValues(alpha: dark ? 0.78 : 0.82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: dark
                  ? scheme.secondary.withValues(alpha: 0.35)
                  : scheme.outline,
            ),
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var slot = 0; slot < _HomePageState._tabs.length; slot++)
                  Expanded(
                    child: _NavItem(
                      icon: _HomePageState._tabs[slot].$1,
                      activeIcon: _HomePageState._tabs[slot].$2,
                      label: tr(_HomePageState._tabs[slot].$3),
                      selected: index == slot,
                      onTap: () => onTap(slot),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: OrdnanceMotion.press,
            curve: OrdnanceMotion.enter,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.55)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? activeIcon : icon, size: 18, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: color,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
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
