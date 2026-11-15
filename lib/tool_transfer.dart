import 'gun_cabinet_data.dart';
import 'range_session.dart';
import 'screens/ammo_inventory_screen.dart';

/// Merge armory, ammunition, and range sessions from an export.
/// Existing rows with the same firearm name, ammo name, or session id stay.
Future<int> mergeToolPayload(Map<String, dynamic> json) async {
  var added = 0;
  final profilesIn = json['gunProfiles'];
  if (profilesIn is List) {
    final profiles = await loadGunProfiles();
    for (final raw in profilesIn) {
      if (raw is! Map) continue;
      final profile =
          GunProfile.fromJson(Map<String, dynamic>.from(raw));
      if (profile.gunName.isEmpty) continue;
      if (profiles.any((p) => p.gunName == profile.gunName)) continue;
      profiles.add(profile);
      added++;
    }
    await saveGunProfiles(profiles);
    cabinetProfilesCache = profiles;
  }
  final ammoIn = json['ammoItems'];
  if (ammoIn is List) {
    final items = await loadAmmoItems();
    for (final raw in ammoIn) {
      if (raw is! Map) continue;
      final item = AmmoItem.fromJson(Map<String, dynamic>.from(raw));
      if (item.name.isEmpty) continue;
      if (items.any((e) => e.name == item.name && e.caliber == item.caliber)) {
        continue;
      }
      items.add(item);
      added++;
    }
    await saveAmmoItems(items);
  }
  final sessionsIn = json['rangeSessions'];
  if (sessionsIn is List) {
    final sessions = await loadRangeSessions();
    for (final raw in sessionsIn) {
      if (raw is! Map) continue;
      final session =
          RangeSession.fromJson(Map<String, dynamic>.from(raw));
      if (session.id.isEmpty) continue;
      if (sessions.any((s) => s.id == session.id)) continue;
      sessions.add(session);
      added++;
    }
    await saveRangeSessions(sessions);
  }
  return added;
}
