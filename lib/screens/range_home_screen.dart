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
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(tr('range_log_session')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(tr('cancel'))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr('save'))),
          ],
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

  @override
  Widget build(BuildContext context) {
    final grey = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8A8578)
        : const Color(0xFF9A917F);
    final due = _due;
    final low = _ammo.where((a) => a.isLow).toList();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const OrdnanceAppBar(),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 120),
        children: [
          Text(tr('range_home_title'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(tr('range_home_sub'),
              style: TextStyle(color: grey, fontSize: 13)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _log,
            icon: const Icon(Icons.add),
            label: Text(tr('range_log_session')),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RangeTripScreen())),
            child: Text(tr('range_trip_link')),
          ),
          if (due.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(tr('range_due'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final p in due)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(p.nickname.isEmpty ? p.gunName : p.nickname),
                subtitle: Text('${p.rounds}'),
                trailing: const Icon(Icons.build_outlined),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MaintenanceScreen())),
              ),
          ],
          if (low.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tr('range_low_ammo'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            for (final a in low)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text('${a.caliber} · ${a.quantity}'),
              ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Text(tr('range_recent'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CommunityRangeScreen())),
                child: Text(tr('range_progress')),
              ),
            ],
          ),
          if (_sessions.isEmpty)
            Text(tr('range_empty'), style: TextStyle(color: grey))
          else
            for (final s in _sessions.take(20))
              Card(
                child: ListTile(
                  title: Text(s.gunName),
                  subtitle: Text(
                      '${s.place} · ${s.distance} · ${s.drill}\n${s.target} · ${s.rounds} · ${s.score}'),
                ),
              ),
        ],
      ),
    );
  }
}
