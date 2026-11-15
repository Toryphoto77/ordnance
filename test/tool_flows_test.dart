import 'package:firearms_catalog/data.dart';
import 'package:firearms_catalog/directory_taxonomy.dart';
import 'package:firearms_catalog/gun_cabinet_data.dart';
import 'package:firearms_catalog/models.dart';
import 'package:firearms_catalog/range_session.dart';
import 'package:firearms_catalog/screens/ammo_inventory_screen.dart';
import 'package:firearms_catalog/tool_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('directory covers the shooting types', () {
    final seen = <String>{};
    for (final gun in guns) {
      seen.addAll(firearmTypeIds(gun));
    }
    const required = [
      'semi_pistol',
      'revolver',
      'pcc',
      'bolt_rifle',
      'semi_rifle',
      'lever_rifle',
      'pump_rifle',
      'break_rifle',
      'muzzleloader',
      'precision',
      'pump_shotgun',
      'semi_shotgun',
      'over_under',
      'side_by_side',
      'bullpup_shotgun',
    ];
    expect(seen.containsAll(required), isTrue,
        reason: 'missing ${required.where((id) => !seen.contains(id)).toList()}');
    expect(guns.where(isRimfireGun), isNotEmpty);
    expect(guns.where((g) => g.name == '北方工业 JW-15').single.source, isNotEmpty);
    expect(guns.where((g) => g.nameEn == 'Ruger PC Carbine').single.twist, '1:10"');
  });

  test('only edition-cited handbook rows count as load data', () {
    final cited = citedReloadLoads(reloadLoads);
    expect(cited, isNotEmpty);
    for (final load in cited) {
      expect(reloadLoadIsCited(load), isTrue);
    }
    expect(
      reloadLoadIsCited(const ReloadLoad(
        caliber: '9×19mm',
        bullet: 'example',
        powder: 'example',
        startCharge: '',
        maxCharge: '',
        col: '',
        primer: '',
        brass: '',
        source: '',
        manual: '',
      )),
      isFalse,
    );
    expect(
      reloadLoadIsCited(const ReloadLoad(
        caliber: '9×19mm',
        bullet: 'example',
        powder: 'example',
        startCharge: '1.0gr',
        maxCharge: '1.1gr',
        col: '1.0',
        primer: '',
        brass: '',
        source: 'somewhere',
        manual: '版本未确认',
      )),
      isFalse,
    );
  });

  test('a session consumes ammo and raises the firearm round count', () {
    final ammo = [
      AmmoItem(caliber: '9×19mm', name: 'Practice 115', quantity: 50, lot: 'L1'),
    ];
    final result = consumeAmmoForSession(
      items: ammo,
      ammoName: 'Practice 115',
      rounds: 20,
      date: '2026-11-15',
    );
    expect(result.consumed, 20);
    expect(result.short, isFalse);
    expect(result.items.single.quantity, 30);
    expect(result.movement!.delta, -20);
    expect(ammo.single.quantity, 50);
    expect(roundsAfterSession(100, 20), 120);

    final short = consumeAmmoForSession(
      items: ammo,
      ammoName: 'Practice 115',
      rounds: 80,
      date: '2026-11-15',
    );
    expect(short.short, isTrue);
    expect(short.consumed, 50);
    expect(short.items.single.quantity, 0);
  });

  test('maintenance is due from the interval the shooter set', () {
    final now = DateTime(2026, 11, 15);
    final byRounds = maintenanceStatus(
      currentRounds: 600,
      lastSnapshotRounds: 0,
      lastService: DateTime(2026, 11, 1),
      everyRounds: 500,
      everyDays: 90,
      now: now,
    );
    expect(byRounds.due, isTrue);
    expect(byRounds.reason, 'rounds');

    final byTime = maintenanceStatus(
      currentRounds: 10,
      lastSnapshotRounds: 0,
      lastService: DateTime(2026, 1, 1),
      everyRounds: 500,
      everyDays: 90,
      now: now,
    );
    expect(byTime.due, isTrue);
    expect(byTime.reason, 'time');

    final fresh = maintenanceStatus(
      currentRounds: 10,
      lastSnapshotRounds: 0,
      lastService: DateTime(2026, 11, 1),
      everyRounds: 500,
      everyDays: 90,
      now: now,
    );
    expect(fresh.due, isFalse);
  });

  test('community blocks sales, manufacturing, and unpublished loads', () {
    expect(communityPostBlockReason('Range log', '10 rounds at 25 m'), isNull);
    expect(
      communityPostBlockReason('Note', 'Hornady 9th edition lists this'),
      isNull,
    );
    expect(communityPostBlockReason('WTS optic', 'for sale'), 'blocked');
    expect(communityPostBlockReason('Help', 'give me a load for this'), 'blocked');
    expect(communityPostBlockReason('How', 'how to manufacture a receiver'), 'blocked');
  });

  test('armory and session json keep new fields', () {
    final profile = GunProfile(
      gunName: 'Example',
      nickname: 'Range',
      serial: 'optional',
      rounds: 40,
      maintEveryRounds: 250,
    );
    final again = GunProfile.fromJson(profile.toJson());
    expect(again.nickname, 'Range');
    expect(again.serial, 'optional');
    expect(again.rounds, 40);
    expect(again.maintEveryRounds, 250);

    final session = RangeSession(
      id: 's1',
      dateMs: 1,
      gunName: 'Example',
      drill: 'Bill drill',
      rounds: 6,
      score: '2.4 s',
    );
    final progress = sessionProgress(
      [session, session],
      gunName: 'Example',
      drill: 'Bill drill',
    );
    expect(progress, hasLength(2));
    expect(RangeSession.fromJson(session.toJson()).drill, 'Bill drill');
  });
}
