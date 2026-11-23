import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../community_store.dart';
import '../gun_cabinet_data.dart';
import '../i18n.dart';
import '../range_session.dart';
import 'ammo_inventory_screen.dart';
import 'maintenance_screen.dart';
import '../tool_logic.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/instrument.dart';
import '../widgets/ordnance_buttons.dart';
import '../widgets/ordnance_sheet.dart';
import 'community_range_screen.dart';
import 'gun_picker_dialog.dart';
import 'range_trip_screen.dart';

/// Today surface: sessions, maintenance that is due, and low ammunition.
class RangeHomeScreen extends StatefulWidget {
  const RangeHomeScreen({super.key});

  @override
  State<RangeHomeScreen> createState() => _RangeHomeScreenState();
}

class _RangeHomeScreenState extends State<RangeHomeScreen> {
  List<GunProfile> _profiles = [];
  List<RangeSession> _sessions = [];
  List<AmmoItem> _ammo = [];
  List<MaintenanceRecord> _service = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await loadGunProfiles();
    final sessions = await loadRangeSessions();
    final ammo = await loadAmmoItems();
    final service = await _loadService();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _sessions = sessions;
      _ammo = ammo;
      _service = service;
    });
    cabinetProfilesCache = profiles;
  }

  Future<List<MaintenanceRecord>> _loadService() async {
    try {
      const channel = MethodChannel('gunsmap/prefs');
      final raw = await channel
          .invokeMethod<String>('getString', {'key': 'maintenance_log_v1'})
          .timeout(const Duration(seconds: 2));
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(MaintenanceRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  DateTime? _lastServiceDate(String gunName) {
    DateTime? best;
    for (final row in _service) {
      if (row.gunName != gunName) continue;
      final parsed = DateTime.tryParse(row.date);
      if (parsed == null) continue;
      if (best == null || parsed.isAfter(best)) best = parsed;
    }
    return best;
  }

  int _lastSnapshot(String gunName) {
    MaintenanceRecord? best;
    for (final row in _service) {
      if (row.gunName != gunName) continue;
      if (best == null || row.date.compareTo(best.date) > 0) best = row;
    }
    if (best == null) return -1;
    if (best.snapshotRounds >= 0) return best.snapshotRounds;
    return -1;
  }

  List<GunProfile> get _due {
    final now = DateTime.now();
    return _profiles.where((p) {
      return maintenanceStatus(
        currentRounds: p.rounds,
        lastSnapshotRounds: _lastSnapshot(p.gunName),
        lastService: _lastServiceDate(p.gunName),
        everyRounds: p.maintEveryRounds,
        everyDays: p.maintEveryDays,
        now: now,
      ).due;
    }).toList();
  }

  Future<void> _log() async {
    var gunName = _profiles.isEmpty ? '' : _profiles.first.gunName;
    final place = TextEditingController();
    final distance = TextEditingController();
    final drill = TextEditingController();
    final target = TextEditingController();
    final rounds = TextEditingController();
    final score = TextEditingController();
    final notes = TextEditingController();
    var ammoName = _ammo.isEmpty ? '' : _ammo.first.name;
    final lot = TextEditingController(
        text: _ammo.isEmpty ? '' : (_ammo.first.lot.isEmpty ? _ammo.first.batchNo : _ammo.first.lot));
    final saved = await showOrdnanceSheet<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr('range_log_session'),
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
                DropdownButton<String>(
                  isExpanded: true,
                  value: gunName.isEmpty ? null : gunName,
                  hint: Text(tr('range_no_gun')),
                  items: [
                    for (final p in _profiles)
                      DropdownMenuItem(
                        value: p.gunName,
                        child: Text(p.nickname.isEmpty
                            ? p.gunName
                            : '${p.nickname} · ${p.gunName}'),
                      ),
                  ],
                  onChanged: (v) => setLocal(() => gunName = v ?? ''),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      final gun = await showGunPickerDialog(ctx);
                      if (gun == null) return;
                      setLocal(() {
                        gunName = gun.name;
                        if (_profiles.every((p) => p.gunName != gun.name)) {
                          _profiles = [
                            ..._profiles,
                            GunProfile(gunName: gun.name),
                          ];
                        }
                      });
                    },
                    child: Text(tr('detail_add_armory')),
                  ),
                ),
                TextField(
                    controller: place,
                    decoration:
                        InputDecoration(labelText: tr('range_field_place'))),
                TextField(
                    controller: distance,
                    decoration: InputDecoration(
                        labelText: tr('range_field_distance'))),
                TextField(
                    controller: drill,
                    decoration:
                        InputDecoration(labelText: tr('range_field_drill'))),
                TextField(
                    controller: target,
                    decoration:
                        InputDecoration(labelText: tr('range_field_target'))),
                TextField(
                    controller: rounds,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(labelText: tr('range_field_rounds'))),
                DropdownButton<String>(
                  isExpanded: true,
                  value: ammoName.isEmpty ? null : ammoName,
                  hint: Text(tr('range_field_ammo')),
                  items: [
                    for (final a in _ammo)
                      DropdownMenuItem(value: a.name, child: Text(a.name)),
                  ],
                  onChanged: (v) {
                    setLocal(() {
                      ammoName = v ?? '';
                      final match = _ammo.where((a) => a.name == ammoName);
                      if (match.isNotEmpty) {
                        final item = match.first;
                        lot.text = item.lot.isEmpty ? item.batchNo : item.lot;
                      }
                    });
                  },
                ),
                TextField(
                    controller: lot,
                    decoration:
                        InputDecoration(labelText: tr('range_field_lot'))),
                TextField(
                    controller: score,
                    decoration:
                        InputDecoration(labelText: tr('range_field_score'))),
                TextField(
                    controller: notes,
                    decoration:
                        InputDecoration(labelText: tr('range_field_notes'))),
                const SizedBox(height: 16),
                Row(
                  children: [
                    AppButton.text(
                      label: tr('cancel'),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: tr('save'),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    );
    final fired = int.tryParse(rounds.text.trim()) ?? 0;
    final fields = (
      place: place.text.trim(),
      distance: distance.text.trim(),
      drill: drill.text.trim(),
      target: target.text.trim(),
      score: score.text.trim(),
      notes: notes.text.trim(),
      lot: lot.text.trim(),
    );
    place.dispose();
    distance.dispose();
    drill.dispose();
    target.dispose();
    rounds.dispose();
    score.dispose();
    notes.dispose();
    lot.dispose();
    if (saved != true || !mounted) return;
    if (gunName.isEmpty) {
      showAppToast(context, tr('range_no_gun'));
      return;
    }
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final consumed = consumeAmmoForSession(
      items: _ammo,
      ammoName: ammoName,
      rounds: fired,
      date: date,
    );
    await saveAmmoItems(consumed.items);
    if (consumed.movement != null) await addAmmoMovement(consumed.movement!);
    final profiles = await loadGunProfiles();
    final idx = profiles.indexWhere((p) => p.gunName == gunName);
    if (idx < 0) {
      profiles.add(GunProfile(
          gunName: gunName, rounds: roundsAfterSession(0, fired)));
    } else {
      profiles[idx].rounds =
          roundsAfterSession(profiles[idx].rounds, fired);
    }
    await saveGunProfiles(profiles);
    cabinetProfilesCache = profiles;
    final session = RangeSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      dateMs: today.millisecondsSinceEpoch,
      gunName: gunName,
      place: fields.place,
      distance: fields.distance,
      drill: fields.drill,
      target: fields.target,
      rounds: fired,
      ammoName: ammoName,
      lot: fields.lot,
      score: fields.score,
      notes: fields.notes,
    );
    final sessions = await loadRangeSessions();
    sessions.insert(0, session);
    await saveRangeSessions(sessions);
    final meters = int.tryParse(fields.distance) ?? 0;
    communityStore.addRangeScore(RangeScore(
      gunName: gunName,
      distance: meters,
      shots: fired,
      groupSize: 0,
      date: today,
      note: fields.notes,
      ammo: ammoName,
      target: fields.target,
      score: fields.score,
    ));
    if (!mounted) return;
    showAppToast(
        context,
        consumed.short ? tr('range_short_stock') : tr('range_saved'));
    await _load();
  }

  int get _monthRounds {
    final now = DateTime.now();
    var total = 0;
    for (final s in _sessions) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.dateMs);
      if (d.year == now.year && d.month == now.month) total += s.rounds;
    }
    return total;
  }

  List<RangeSession> get _recent {
    final copy = [..._sessions]
      ..sort((a, b) => b.dateMs.compareTo(a.dateMs));
    return copy;
  }

  double _serviceFraction(GunProfile p) {
    final interval = p.maintEveryRounds <= 0 ? 500 : p.maintEveryRounds;
    final last = _lastSnapshot(p.gunName);
    final since = last < 0 ? p.rounds : p.rounds - last;
    if (interval <= 0) return 0;
    return (since / interval).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = _due;
    final low = _ammo.where((a) => a.isLow).toList();
    final recent = _recent;
    final last = recent.isEmpty ? null : recent.first;
    final spark = recent.reversed.take(8).map((s) => s.rounds.toDouble()).toList();
    var hottestT = 0.0;
    for (final p in _profiles) {
      final t = _serviceFraction(p);
      if (t > hottestT) hottestT = t;
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OrdnanceAppBar(
        title: tr('range_home_title'),
        showWeather: true,
      ),
      body: ListView(
        padding: ordnanceListPadding(context, root: true, bottom: 128),
        children: [
          if (recent.isEmpty)
            EmptyInstrument(
              message: tr('range_empty'),
              action: AppButton.primary(
                label: tr('range_log_session'),
                icon: Icons.add,
                onPressed: _log,
              ),
            )
          else
            HudPanel(
              glow: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressRing(
                    value: hottestT,
                    center: '$_monthRounds',
                    caption: tr('inst_this_month'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow(tr('range_recent')),
                        const SizedBox(height: 4),
                        Text(last!.gunName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${last.place} · ${last.distance} · ${last.score}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Sparkline(values: spark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (recent.isNotEmpty)
            AppButton.primary(
              label: tr('range_log_session'),
              icon: Icons.add,
              onPressed: _log,
            ),
          const SizedBox(height: 8),
          AppButton.secondary(
            label: tr('range_trip_link'),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RangeTripScreen())),
          ),
          if (due.isNotEmpty) ...[
            const SizedBox(height: 16),
            Eyebrow(tr('range_due')),
            const SizedBox(height: 8),
            for (var i = 0; i < due.length; i++)
              StaggerIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HudPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(due[i].nickname.isEmpty
                          ? due[i].gunName
                          : due[i].nickname),
                      subtitle: Text('${due[i].rounds}'),
                      trailing: Icon(Icons.build_outlined,
                          color: scheme.primary),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MaintenanceScreen())),
                    ),
                  ),
                ),
              ),
          ],
          if (low.isNotEmpty) ...[
            const SizedBox(height: 8),
            Eyebrow(tr('range_low_ammo')),
            const SizedBox(height: 8),
            HudPanel(
              child: Column(
                children: [
                  for (final a in low)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.name),
                      subtitle: Text('${a.caliber} · ${a.quantity}'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Eyebrow(tr('range_recent'))),
              AppButton.text(
                label: tr('range_progress'),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityRangeScreen())),
              ),
            ],
          ),
          if (recent.isNotEmpty)
            for (var i = 0; i < recent.take(12).length; i++)
              StaggerIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HudPanel(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recent[i].gunName,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${recent[i].place} · ${recent[i].distance} · ${recent[i].drill}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '${recent[i].rounds} · ${recent[i].score}',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
