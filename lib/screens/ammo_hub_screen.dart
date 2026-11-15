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
    final grey = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8A8578)
        : const Color(0xFF9A917F);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const OrdnanceAppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 120),
        children: [
          Text(tr('ammo_hub_title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tr('ammo_hub_sub'), style: TextStyle(color: grey, fontSize: 13)),
          const SizedBox(height: 8),
          Text(tr('load_caution'), style: TextStyle(color: grey, fontSize: 12)),
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
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => page())),
      ),
    );
  }
}
