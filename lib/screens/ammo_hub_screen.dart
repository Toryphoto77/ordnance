import 'package:flutter/material.dart';

import '../i18n.dart';
import '../widgets/app_top_bar.dart';
import 'accessories_screen.dart';
import 'ammo_inventory_screen.dart';
import 'reload_log_screen.dart';
import 'reloading_screen.dart';
import 'tools_screen.dart';

/// Ammunition and handloading live together. Load numbers stay on the
/// reloading screen, and only cited handbook rows are shown there.
class AmmoHubScreen extends StatelessWidget {
  const AmmoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OrdnanceAppBar(title: tr('ammo_hub_title')),
      body: ListView(
        padding: ordnanceListPadding(context, root: true, bottom: 128),
        children: [
          Text(tr('ammo_hub_sub'), style: muted),
          const SizedBox(height: 8),
          Text(tr('load_caution'), style: muted),
          const SizedBox(height: 16),
          _tile(context, Icons.inventory_2_outlined, tr('ammo_open_inventory'),
              () => const AmmoInventoryScreen()),
          _tile(context, Icons.menu_book_outlined, tr('ammo_open_loads'),
              () => const ReloadingScreen()),
          _tile(context, Icons.fact_check_outlined, tr('ammo_open_log'),
              () => const ReloadLogScreen()),
          _tile(context, Icons.handyman_outlined, tr('acc_catalog_title'),
              () => const AccessoriesScreen()),
          _tile(context, Icons.straighten_outlined, tr('tab_tools'),
              () => const ToolsScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
      Widget Function() page) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page())),
        ),
      ),
    );
  }
}
