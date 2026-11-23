import 'package:flutter/material.dart';

import '../data.dart';
import '../directory_taxonomy.dart';
import '../english_terms.dart';
import '../gun_cabinet_data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/instrument.dart';
import '../widgets/ordnance_buttons.dart';
import 'gun_detail_screen.dart';
import 'gun_list_screen.dart';
import 'news_screen.dart';

/// Firearms Directory: find a type, then open a tool-oriented detail page.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  bool _searchExpanded = false;
  String? _type;
  String? _action;
  String? _use;
  String? _family;
  bool _rimfire = false;

  bool _matches(Gun g) {
    if (_type != null && !firearmTypeIds(g).contains(_type)) return false;
    if (_rimfire && !isRimfireGun(g)) return false;
    if (_action != null && actionFamily(g) != _action) return false;
    if (_use != null && !firearmUseIds(g).contains(_use)) return false;
    if (_family != null && !caliberFamilyMatch(g, _family!)) return false;
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return g.name.toLowerCase().contains(q) ||
        (g.nameEn ?? '').toLowerCase().contains(q) ||
        g.vendor.toLowerCase().contains(q) ||
        g.caliber.toLowerCase().contains(q) ||
        g.action.toLowerCase().contains(q) ||
        categoryMatches(g.category, q);
  }

  bool get _filtering =>
      _query.trim().isNotEmpty ||
      _type != null ||
      _action != null ||
      _use != null ||
      _family != null ||
      _rimfire;

  void _clear() {
    setState(() {
      _type = null;
      _action = null;
      _use = null;
      _family = null;
      _rimfire = false;
      _query = '';
      _searchExpanded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    final results = guns.where(_matches).toList();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OrdnanceAppBar(
        title: tr('dir_title'),
        actions: [
          AppIconButton(
            tooltip: tr('search_gun_hint'),
            icon: _searchExpanded ? Icons.close : Icons.search,
            onPressed: () => setState(() {
              _searchExpanded = !_searchExpanded;
              if (!_searchExpanded) _query = '';
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
          padding: ordnanceListPadding(context, root: true, bottom: 128),
          children: [
            HudPanel(
              glow: true,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(tr('inst_firearms')),
                        FigureText('${guns.length}'),
                        const SizedBox(height: 4),
                        Text(tr('dir_sub'),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  ProgressRing(
                    value: _filtering
                        ? (results.isEmpty
                            ? 0
                            : results.length / guns.length)
                        : 1,
                    center: _filtering ? '${results.length}' : '${directoryTypeIds.length}',
                    caption: tr('tab_catalog'),
                    size: 78,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_searchExpanded) ...[
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr('search_gun_hint'),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ],
            const SizedBox(height: 8),
            _chipRow(
              label: tr('dir_action'),
              ids: actionFamilyIds,
              selected: _action,
              text: (id) => tr('act_$id'),
              onPick: (id) => setState(() => _action = _action == id ? null : id),
            ),
            _chipRow(
              label: tr('dir_use'),
              ids: useCaseIds,
              selected: _use,
              text: (id) => tr('use_$id'),
              onPick: (id) => setState(() => _use = _use == id ? null : id),
            ),
            _chipRow(
              label: tr('dir_caliber'),
              ids: caliberFamilyIds,
              selected: _family,
              text: (id) => tr('fam_$id'),
              onPick: (id) =>
                  setState(() => _family = _family == id ? null : id),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilterChip(
                  label: Text(tr('dir_rimfire')),
                  selected: _rimfire,
                  onSelected: (v) => setState(() => _rimfire = v),
                ),
                const SizedBox(width: 8),
                if (_filtering)
                  AppButton.text(label: tr('dir_clear'), onPressed: _clear),
              ],
            ),
            const SizedBox(height: 8),
            if (!_filtering) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.05,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: directoryTypeIds.length,
                itemBuilder: (context, i) {
                  final id = directoryTypeIds[i];
                  final count =
                      guns.where((g) => firearmTypeIds(g).contains(id)).length;
                  final selected = _type == id;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withValues(alpha: 0.16)
                          : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? scheme.primary : scheme.outlineVariant,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _type = id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(tr('type_$id'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall),
                              Text('$count',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: muted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final c in categories)
                    ActionChip(
                      label: Text(categoryDisplay(c)),
                      onPressed: () {
                        tapHaptic();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GunListScreen(category: c)),
                        );
                      },
                    ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton.text(
                  label: tr('news_title'),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewsScreen())),
                ),
              ),
            ] else ...[
              Text('${results.length}',
                  style: TextStyle(color: muted, fontSize: 13)),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(tr('dir_empty'),
                      style: TextStyle(color: muted)),
                ),
              for (final g in results.take(80))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      title: Hero(
                        tag: gunHeroTag(g),
                        child: Text(gunDisplayName(g)),
                      ),
                      subtitle: Text(
                          '${vendorDisplay(g.vendor)} · ${g.caliber} · ${actionDisplay(g.action)}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => GunDetailScreen(gun: g)),
                        );
                      },
                    ),
                  ),
                ),
              if (results.length > 80)
                Text(tr('dir_more'), style: TextStyle(color: muted, fontSize: 12)),
            ],
            if (cabinetProfilesCache != null &&
                cabinetProfilesCache!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '${tr('cab_title')} · ${cabinetProfilesCache!.length}',
                    style: TextStyle(color: muted, fontSize: 12)),
              ),
          ],
        ),
    );
  }

  Widget _chipRow({
    required String label,
    required List<String> ids,
    required String? selected,
    required String Function(String) text,
    required ValueChanged<String> onPick,
  }) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                  child: Text(label,
                      style: TextStyle(color: muted, fontSize: 12))),
            ),
            for (final id in ids)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(text(id)),
                  selected: selected == id,
                  onSelected: (_) => onPick(id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
