import 'models.dart';

/// Browsing facets for the Firearms Directory.
/// Types are derived from the existing catalog fields. A firearm can carry
/// more than one type (a bullpup pump shotgun, a pistol-caliber carbine).

const directoryTypeIds = <String>[
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
  'smg',
  'machine_gun',
];

const actionFamilyIds = <String>[
  'bolt',
  'semi',
  'lever',
  'pump',
  'break',
  'revolver',
  'auto',
  'other',
];

const useCaseIds = <String>[
  'range',
  'hunting',
  'competition',
  'defensive',
  'precision',
];

const caliberFamilyIds = <String>[
  '9mm',
  '45',
  '556',
  '308',
  '12ga',
];

bool isRimfireCaliber(String caliber) {
  final c = caliber.toLowerCase();
  if (RegExp(r'\.22[\s-]*(250|hornet|swift|creed|nosler|ppc)|'
          r'\.220|\.222|\.223|\.224|5\.56')
      .hasMatch(c)) {
    // A string can still mention a rimfire alongside a centerfire.
    // Only treat it as rimfire when a rimfire designation is also present.
  }
  return RegExp(
    r'\.22\s*(lr|long\s*rifle|s\b|short|l\b|long\b|wmr|mag)|'
    r'\.22\s*s\s*/|'
    r'22\s*lr|'
    r'\.17\s*hmr|\.17\s*hm2|\.17\s*wsm',
  ).hasMatch(c);
}

bool isRimfireGun(Gun g) => isRimfireCaliber(g.caliber);

bool _pistolCaliber(String caliber) {
  final s = caliber.toLowerCase();
  return s.contains('9×19') ||
      s.contains('9x19') ||
      s.contains('9mm') ||
      s.contains('.45 acp') ||
      s.contains('.40') ||
      s.contains('10mm') ||
      s.contains('5.7×28') ||
      s.contains('5.7x28') ||
      s.contains('.357 sig') ||
      s.contains('.380') ||
      s.contains('.38 super') ||
      s.contains('.45 gap');
}

bool _namedPcc(Gun g) {
  final n = '${g.name} ${g.nameEn ?? ''}'.toLowerCase();
  return n.contains('sub2000') ||
      n.contains('sub-2000') ||
      n.contains('pc carbine') ||
      n.contains('homesteader') ||
      n.contains('mpx') ||
      n.contains('蝎式') ||
      n.contains('scorpion');
}

bool caliberFamilyMatch(Gun g, String family) {
  final c = g.caliber.toLowerCase();
  switch (family) {
    case '9mm':
      return c.contains('9×19') || c.contains('9x19') || c.contains('9mm');
    case '45':
      return c.contains('.45 acp') || c.contains('.45 auto');
    case '556':
      return c.contains('5.56') || c.contains('.223');
    case '308':
      return c.contains('.308') || c.contains('7.62×51') || c.contains('7.62x51');
    case '12ga':
      return c.contains('12号') || c.contains('12 gauge') || c.contains('12ga');
    default:
      return false;
  }
}

String actionFamily(Gun g) {
  final a = g.action;
  if (a.contains('转轮')) return 'revolver';
  if (a.contains('杠杆')) return 'lever';
  if (a.contains('泵')) return 'pump';
  if (a.contains('前装') || a.contains('折开') || a.toLowerCase().contains('break')) {
    return 'break';
  }
  if (a.contains('栓')) return 'bolt';
  if (a.contains('全自动') && !a.contains('半自动')) return 'auto';
  if (a.contains('半自动') ||
      a.contains('导气') ||
      a.contains('活塞') ||
      a.contains('后坐') ||
      a.contains('自由枪机')) {
    return 'semi';
  }
  if (a.contains('全自动')) return 'auto';
  return 'other';
}

bool _precision(Gun g) {
  return g.category == '精确射手步枪' ||
      g.category == '狙击步枪' ||
      g.category == '反器材步枪';
}

bool _overUnder(Gun g) {
  final n = '${g.name} ${g.nameEn ?? ''} ${g.action}'.toLowerCase();
  return n.contains('silver pigeon') ||
      n.contains('citori') ||
      n.contains('over-under') ||
      n.contains('over under') ||
      n.contains('超置');
}

bool _sideBySide(Gun g) {
  final n = '${g.name} ${g.nameEn ?? ''} ${g.action}'.toLowerCase();
  return n.contains('bobwhite') ||
      n.contains('side-by-side') ||
      n.contains('side by side') ||
      n.contains('并列') ||
      n.contains('uplander');
}

bool _bullpupShotgun(Gun g) {
  final n = '${g.name} ${g.nameEn ?? ''}'.toLowerCase();
  return n.contains('ksg') || n.contains('ks7') || n.contains('bullpup');
}

bool _muzzleloader(Gun g) {
  final n = '${g.name} ${g.nameEn ?? ''} ${g.action}'.toLowerCase();
  return g.action.contains('前装') ||
      n.contains('muzzleloader') ||
      n.contains('pursuit');
}

Set<String> firearmTypeIds(Gun g) {
  final types = <String>{};
  if (g.category == '机枪') {
    types.add('machine_gun');
    return types;
  }
  if (g.category == '手枪') {
    types.add(g.action.contains('转轮') ? 'revolver' : 'semi_pistol');
    return types;
  }
  if (g.category == '霰弹枪') {
    if (_bullpupShotgun(g)) types.add('bullpup_shotgun');
    if (g.action.contains('泵')) types.add('pump_shotgun');
    if (_overUnder(g)) types.add('over_under');
    if (_sideBySide(g)) types.add('side_by_side');
    if (g.action.contains('半自动')) types.add('semi_shotgun');
    if (types.isEmpty && g.action.contains('折开')) types.add('over_under');
    return types;
  }
  if (_muzzleloader(g)) {
    types.add('muzzleloader');
    return types;
  }
  final pcc = _pistolCaliber(g.caliber) || _namedPcc(g);
  if (g.category == '冲锋枪') {
    types.add('smg');
    if (pcc) types.add('pcc');
  } else if (pcc && (g.category == '步枪' || _namedPcc(g))) {
    types.add('pcc');
  }
  if (_precision(g)) types.add('precision');
  final rifleLike = g.category == '步枪' ||
      g.category == '精确射手步枪' ||
      g.category == '狙击步枪' ||
      g.category == '反器材步枪';
  if (rifleLike &&
      (g.action.contains('折开') || g.action.toLowerCase().contains('break'))) {
    types.add('break_rifle');
  }
  if (rifleLike && g.action.contains('杠杆')) types.add('lever_rifle');
  if (rifleLike && g.action.contains('泵')) types.add('pump_rifle');
  if (rifleLike && g.action.contains('栓')) types.add('bolt_rifle');
  if (rifleLike &&
      !types.contains('pcc') &&
      (g.action.contains('半自动') ||
          g.action.contains('导气') ||
          g.action.contains('活塞'))) {
    types.add('semi_rifle');
  }
  return types;
}

Set<String> firearmUseIds(Gun g) {
  final types = firearmTypeIds(g);
  final uses = <String>{};
  if (types.contains('machine_gun')) return uses;
  uses.add('range');
  if (types.contains('precision') ||
      types.contains('bolt_rifle') ||
      types.contains('semi_rifle')) {
    uses.add('precision');
  }
  if (types.contains('bolt_rifle') ||
      types.contains('lever_rifle') ||
      types.contains('pump_rifle') ||
      types.contains('break_rifle') ||
      types.contains('muzzleloader') ||
      types.contains('pump_shotgun') ||
      types.contains('semi_shotgun') ||
      types.contains('over_under') ||
      types.contains('side_by_side')) {
    uses.add('hunting');
  }
  if (types.contains('precision') ||
      types.contains('semi_pistol') ||
      types.contains('pcc') ||
      types.contains('semi_shotgun')) {
    uses.add('competition');
  }
  if (types.contains('semi_pistol') ||
      types.contains('revolver') ||
      types.contains('pcc') ||
      types.contains('pump_shotgun')) {
    uses.add('defensive');
  }
  return uses;
}
