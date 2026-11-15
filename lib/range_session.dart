import 'dart:convert';

import 'package:flutter/services.dart';

/// One range session against a firearm the shooter owns.
/// Stored on device. Saving a session is what consumes ammunition and
/// adds to that firearm's round count (see the range screen).
const rangeSessionsKey = 'range_sessions_v1';

class RangeSession {
  String id;
  int dateMs;
  String gunName;
  String place;
  String distance;
  String drill;
  String target;
  int rounds;
  String ammoName;
  String lot;
  String score;
  String notes;

  RangeSession({
    required this.id,
    required this.dateMs,
    required this.gunName,
    this.place = '',
    this.distance = '',
    this.drill = '',
    this.target = '',
    this.rounds = 0,
    this.ammoName = '',
    this.lot = '',
    this.score = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateMs': dateMs,
        'gunName': gunName,
        'place': place,
        'distance': distance,
        'drill': drill,
        'target': target,
        'rounds': rounds,
        'ammoName': ammoName,
        'lot': lot,
        'score': score,
        'notes': notes,
      };

  factory RangeSession.fromJson(Map<String, dynamic> j) => RangeSession(
        id: j['id'] as String? ?? '',
        dateMs: (j['dateMs'] as num?)?.toInt() ?? 0,
        gunName: j['gunName'] as String? ?? '',
        place: j['place'] as String? ?? '',
        distance: j['distance'] as String? ?? '',
        drill: j['drill'] as String? ?? '',
        target: j['target'] as String? ?? '',
        rounds: (j['rounds'] as num?)?.toInt() ?? 0,
        ammoName: j['ammoName'] as String? ?? '',
        lot: j['lot'] as String? ?? '',
        score: j['score'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
      );
}

const _sessionChannel = MethodChannel('gunsmap/prefs');

Future<List<RangeSession>> loadRangeSessions() async {
  try {
    final raw = await _sessionChannel
        .invokeMethod<String>('getString', {'key': rangeSessionsKey})
        .timeout(const Duration(seconds: 2));
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(RangeSession.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveRangeSessions(List<RangeSession> sessions) async {
  try {
    await _sessionChannel.invokeMethod('setString', {
      'key': rangeSessionsKey,
      'value': jsonEncode(sessions.map((s) => s.toJson()).toList()),
    }).timeout(const Duration(seconds: 2));
  } catch (_) {}
}

/// Last few scores for the same firearm and drill, newest first.
List<RangeSession> sessionProgress(
  List<RangeSession> sessions, {
  required String gunName,
  required String drill,
  int limit = 8,
}) {
  final rows = sessions
      .where((s) =>
          s.gunName == gunName &&
          (drill.isEmpty || s.drill == drill) &&
          s.score.trim().isNotEmpty)
      .toList()
    ..sort((a, b) => b.dateMs.compareTo(a.dateMs));
  if (rows.length <= limit) return rows;
  return rows.sublist(0, limit);
}
