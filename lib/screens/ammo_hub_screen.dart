import 'package:flutter/material.dart';

import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/instrument.dart';
import 'accessories_screen.dart';
import 'ammo_inventory_screen.dart';
import 'reload_log_screen.dart';
import 'reloading_screen.dart';
import 'tools_screen.dart';

/// Ammunition and handloading live together. Load numbers stay on the
/// reloading screen, and only cited handbook rows are shown there.
class AmmoHubScreen extends StatefulWidget {
  const AmmoHubScreen({super.key});

  @override
  State<AmmoHubScreen> createState() => _AmmoHubScreenState();
}

class _AmmoHubScreenState extends State<AmmoHubScreen> {
  List<AmmoItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await loadAmmoItems();
    if (!mounted) return;
    setState(() => _items = items);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        );
    final total = _items.fold<int>(0, (a, e) => a + e.quantity);
    final low = _items.where((e) => e.isLow).length;
    final byCaliber = <String, int>{};
    for (final item in _items) {
      final key = item.caliber.isEmpty ? '—' : item.caliber;
      byCaliber[key] = (byCaliber[key] ?? 0) + item.quantity;
    }
    final bars = byCaliber.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OrdnanceAppBar(title: tr('ammo_hub_title')),
      body: ListView(
        padding: ordnanceListPadding(context, root: true, bottom: 128),
        children: [
          if (_items.isEmpty)
            EmptyInstrument(message: tr('ammo_hub_sub'))
          else
            HudPanel(
              glow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Eyebrow(tr('inst_on_hand')),
                            FigureText('$total'),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Eyebrow(tr('inst_low')),
                          FigureText('$low', size: 28),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MiniBars(rows: [for (final e in bars) (e.key, e.value)]),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Text(tr('load_caution'), style: muted),
          const SizedBox(height: 14),
          _tile(context, 0, Icons.inventory_2_outlined, tr('ammo_open_inventory'),
              () => const AmmoInventoryScreen()),
          _tile(context, 1, Icons.menu_book_outlined, tr('ammo_open_loads'),
              () => const ReloadingScreen()),
          _tile(context, 2, Icons.fact_check_outlined, tr('ammo_open_log'),
              () => const ReloadLogScreen()),
          _tile(context, 3, Icons.handyman_outlined, tr('acc_catalog_title'),
              () => const AccessoriesScreen()),
          _tile(context, 4, Icons.straighten_outlined, tr('tab_tools'),
              () => const ToolsScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, int index, IconData icon, String title,
      Widget Function() page) {
    final scheme = Theme.of(context).colorScheme;
    return StaggerIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: HudPanel(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: Icon(icon, color: scheme.primary),
            title: Text(title),
            trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => page())),
          ),
        ),
      ),
    );
  }
}
