import 'package:flutter/material.dart';

import '../data.dart';
import '../directory_taxonomy.dart';
import '../english_terms.dart';
import '../gun_cabinet_data.dart';
import '../haptics.dart';
import '../i18n.dart';
import '../models.dart';
import '../widgets/app_top_bar.dart';
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    final bronze = dark ? const Color(0xFFC9A86A) : const Color(0xFF6B5B3E);
    final ink = dark ? const Color(0xFFEDE8DF) : const Color(0xFF2E2A24);
    final cardBg = dark ? const Color(0xFF0D0D0D) : Colors.white;
    final results = guns.where(_matches).toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const OrdnanceAppBar(),
      body: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8 + kToolbarHeight, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('dir_title'),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ink)),
                      Text(tr('dir_sub'),
                          style: TextStyle(color: grey, fontSize: 12)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _searchExpanded = !_searchExpanded;
                    if (!_searchExpanded) _query = '';
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cardBg,
                    ),
                    child: Icon(_searchExpanded ? Icons.close : Icons.search,
                        color: bronze, size: 22),
                  ),
                ),
              ],
            ),
            if (_searchExpanded) ...[
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: tr('search_gun_hint'),
                  hintStyle: TextStyle(color: grey),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
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
              bronze: bronze,
              grey: grey,
              cardBg: cardBg,
            ),
            _chipRow(
              label: tr('dir_use'),
              ids: useCaseIds,
              selected: _use,
              text: (id) => tr('use_$id'),
              onPick: (id) => setState(() => _use = _use == id ? null : id),
              bronze: bronze,
              grey: grey,
              cardBg: cardBg,
            ),
            _chipRow(
              label: tr('dir_caliber'),
              ids: caliberFamilyIds,
              selected: _family,
              text: (id) => tr('fam_$id'),
              onPick: (id) =>
                  setState(() => _family = _family == id ? null : id),
              bronze: bronze,
              grey: grey,
              cardBg: cardBg,
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
                  TextButton(onPressed: _clear, child: Text(tr('dir_clear'))),
              ],
            ),
            const SizedBox(height: 8),
            if (!_filtering) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: directoryTypeIds.length,
                itemBuilder: (context, i) {
                  final id = directoryTypeIds[i];
                  final count =
                      guns.where((g) => firearmTypeIds(g).contains(id)).length;
                  return GestureDetector(
                    onTap: () {
                      tapHaptic();
                      setState(() => _type = id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(tr('type_$id'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: ink)),
                          Text('$count',
                              style: TextStyle(color: grey, fontSize: 12)),
                        ],
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
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NewsScreen())),
                  child: Text(tr('news_title')),
                ),
              ),
            ] else ...[
              Text('${results.length}',
                  style: TextStyle(color: grey, fontSize: 13)),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(tr('dir_empty'),
                      style: TextStyle(color: grey)),
                ),
              for (final g in results.take(80))
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(gunDisplayName(g)),
                    subtitle: Text(
                        '${vendorDisplay(g.vendor)} · ${g.caliber} · ${actionDisplay(g.action)}'),
                    onTap: () {
                      tapHaptic();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => GunDetailScreen(gun: g)),
                      );
                    },
                  ),
                ),
              if (results.length > 80)
                Text(tr('dir_more'), style: TextStyle(color: grey, fontSize: 12)),
            ],
            if (cabinetProfilesCache != null &&
                cabinetProfilesCache!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                    '${tr('cab_title')} · ${cabinetProfilesCache!.length}',
                    style: TextStyle(color: grey, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chipRow({
    required String label,
    required List<String> ids,
    required String? selected,
    required String Function(String) text,
    required ValueChanged<String> onPick,
    required Color bronze,
    required Color grey,
    required Color cardBg,
  }) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
                child: Text(label, style: TextStyle(color: grey, fontSize: 12))),
          ),
          for (final id in ids)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => onPick(id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == id ? bronze : cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(text(id),
                      style: TextStyle(
                          fontSize: 12,
                          color: selected == id ? Colors.black : grey)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
