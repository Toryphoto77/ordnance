import 'models.dart';
import 'screens/ammo_inventory_screen.dart';

/// A published load is shown only when the handbook name includes an edition
/// or year and the citation is not marked unconfirmed. Anything else stays
/// in the data file but is not presented as load data.
bool reloadLoadIsCited(ReloadLoad load) {
  final manual = load.manual.trim();
  final source = load.source.trim();
  if (manual.isEmpty || source.isEmpty) return false;
  final blob = '$manual $source';
  const blocked = ['未确认', '版本未', '现编', '估计', 'estimated', 'unconfirmed'];
  for (final word in blocked) {
    if (blob.toLowerCase().contains(word.toLowerCase())) return false;
  }
  return RegExp(r'(第\s*\d+\s*版|\d{4}|edition)', caseSensitive: false)
      .hasMatch(manual);
}

List<ReloadLoad> citedReloadLoads(List<ReloadLoad> loads) =>
    loads.where(reloadLoadIsCited).toList();

/// Composer and comment gate. Returns a stable reason id, or null when the
/// text is allowed. Unpublished loads, manufacturing instructions, and
/// sales are refused. Citing a published handbook is allowed.
String? communityPostBlockReason(String title, String content) {
  final text = '$title\n$content'.toLowerCase();
  const phrases = <String>[
    'for sale',
    'wts ',
    'wtb ',
    'parts for sale',
    'how to manufacture',
    'how to build a gun',
    'how to make a gun',
    'how to make ammo',
    'how to make ammunition',
    'ghost gun',
    '80% lower',
    'pet load',
    'give me a load',
    'custom load',
    'what powder charge',
    'how much powder should',
    'unpublished load',
    '出售',
    '求购',
    '转让配件',
    '零件出售',
    '自制枪',
    '如何制造',
    '制造教程',
    '怎么造弹',
    '给个装药',
    '私货配方',
    '帮我算装药',
    '非手册装药',
  ];
  for (final phrase in phrases) {
    if (text.contains(phrase)) return 'blocked';
  }
  return null;
}

class AmmoConsumeResult {
  final List<AmmoItem> items;
  final AmmoMovement? movement;
  final int consumed;
  final bool short;
  const AmmoConsumeResult({
    required this.items,
    required this.movement,
    required this.consumed,
    required this.short,
  });
}

AmmoItem copyAmmoItem(AmmoItem e) => AmmoItem(
      caliber: e.caliber,
      name: e.name,
      quantity: e.quantity,
      note: e.note,
      kind: e.kind,
      roundsPerBox: e.roundsPerBox,
      lowAt: e.lowAt,
      location: e.location,
      batchNo: e.batchNo,
      manufacturer: e.manufacturer,
      intendedGun: e.intendedGun,
      storageClimate: e.storageClimate,
      lot: e.lot,
    );

/// Deduct fired rounds from the named inventory row. Never goes below zero.
/// A short result means the shelf had fewer rounds than the session.
AmmoConsumeResult consumeAmmoForSession({
  required List<AmmoItem> items,
  required String ammoName,
  required int rounds,
  required String date,
}) {
  final copy = items.map(copyAmmoItem).toList();
  if (ammoName.trim().isEmpty || rounds <= 0) {
    return AmmoConsumeResult(
        items: copy, movement: null, consumed: 0, short: false);
  }
  final idx = copy.indexWhere((e) => e.name == ammoName);
  if (idx < 0) {
    return AmmoConsumeResult(
        items: copy, movement: null, consumed: 0, short: true);
  }
  final have = copy[idx].quantity;
  final take = rounds > have ? have : rounds;
  copy[idx].quantity = have - take;
  final movement = take == 0
      ? null
      : AmmoMovement(
          date: date,
          name: copy[idx].name,
          caliber: copy[idx].caliber,
          delta: -take,
          reason: 'range',
        );
  return AmmoConsumeResult(
    items: copy,
    movement: movement,
    consumed: take,
    short: take < rounds,
  );
}

int roundsAfterSession(int current, int fired) =>
    current + (fired < 0 ? 0 : fired);

class MaintenanceDue {
  final bool due;
  final String reason;
  const MaintenanceDue({required this.due, required this.reason});
}

/// Due when the user-set round interval or day interval has elapsed since
/// the last logged service. Defaults are 500 rounds and 90 days. A firearm
/// with no service date is not marked late by the calendar.
MaintenanceDue maintenanceStatus({
  required int currentRounds,
  required int lastSnapshotRounds,
  required DateTime? lastService,
  required int everyRounds,
  required int everyDays,
  required DateTime now,
}) {
  final roundInterval = everyRounds <= 0 ? 500 : everyRounds;
  final dayInterval = everyDays <= 0 ? 90 : everyDays;
  final sinceRounds = lastSnapshotRounds < 0
      ? currentRounds
      : currentRounds - lastSnapshotRounds;
  final roundsDue = sinceRounds >= roundInterval;
  final timeDue = lastService != null &&
      now.difference(lastService).inDays >= dayInterval;
  if (roundsDue && timeDue) {
    return const MaintenanceDue(due: true, reason: 'both');
  }
  if (roundsDue) return const MaintenanceDue(due: true, reason: 'rounds');
  if (timeDue) return const MaintenanceDue(due: true, reason: 'time');
  return const MaintenanceDue(due: false, reason: '');
}
