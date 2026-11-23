/// Names used when an APK is saved or offered for download.
///
/// The installed launcher name comes from Android `android:label`. This
/// helper is only the file name. A Content-Disposition value is trusted
/// when it is already `Ordnance-v*.apk`. Scaffold names such as
/// `app-release.apk` or `firearms_catalog` are replaced.
String ordnanceApkFileName({
  required String version,
  String? contentDisposition,
}) {
  final fromHeader = filenameFromContentDisposition(contentDisposition);
  if (fromHeader != null && isOrdnanceApkName(fromHeader)) return fromHeader;
  final clean = version.trim().replaceAll(RegExp(r'[^0-9A-Za-z._-]'), '');
  final safe = clean.isEmpty ? '0' : clean;
  return 'Ordnance-v$safe.apk';
}

bool isOrdnanceApkName(String name) {
  return RegExp(r'^Ordnance-v\d+\.\d+\.\d+\.apk$', caseSensitive: false)
      .hasMatch(name);
}

/// Parses `filename` / `filename*` from a Content-Disposition header.
String? filenameFromContentDisposition(String? header) {
  if (header == null || header.isEmpty) return null;
  final star = RegExp(
    r"filename\*\s*=\s*(?:UTF-8''|utf-8'')?([^;]+)",
    caseSensitive: false,
  ).firstMatch(header);
  final plain = RegExp(
    r'filename\s*=\s*"?([^";]+)"?',
    caseSensitive: false,
  ).firstMatch(header);
  final raw = (star ?? plain)?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  var name = raw;
  try {
    name = Uri.decodeComponent(raw);
  } catch (_) {}
  name = name.replaceAll(RegExp(r'[/\\]'), '');
  if (!name.toLowerCase().endsWith('.apk')) return null;
  return name;
}
