import 'dart:convert';
import '../widgets/app_toast.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../apk_filename.dart';
import '../i18n.dart';
import '../app_version.dart';
import '../theme_accent.dart';
import '../main.dart';
import '../system_actions.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/glass_dialog.dart';
import '../community_store.dart';
import '../gun_cabinet_data.dart';
import '../range_session.dart';
import '../tool_transfer.dart';
import 'ammo_inventory_screen.dart';
import 'about_screen.dart';
import 'theme_screen.dart';
import 'app_log_screen.dart';
import 'feedback_screen.dart';
import '../haptics.dart';
import '../widgets/instrument.dart';
import 'my_screen.dart';
import 'unit_settings_screen.dart';

/// 设置页：主题切换与关于信息。
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    // 语言切换时整页重译。
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (_, __, ___) => Scaffold(
      extendBodyBehindAppBar: true,
      appBar: SubPageAppBar(title: tr('settings_title')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 16, 28),
        children: [
          HudPanel(
            glow: true,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset('assets/images/app-icon.png',
                      width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ordnance',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Range · Armory · Ammunition',
                          style: TextStyle(color: grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('v$appVersion',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SettingsGroup(
            title: tr('set_display'),
            children: [
              ValueListenableBuilder<Color>(
                valueListenable: accentNotifier,
                builder: (_, accent, __) => ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeModeNotifier,
                  builder: (_, mode, __) => SettingsRow(
                    icon: Icons.palette_outlined,
                    title: tr('appearance'),
                    value: mode == ThemeMode.system
                        ? tr('theme_system')
                        : mode == ThemeMode.light
                            ? tr('theme_light')
                            : tr('theme_dark'),
                    trailing: Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ThemeScreen()),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: ValueListenableBuilder<String>(
                  valueListenable: localeNotifier,
                  builder: (_, locale, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('language'),
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final entry in localeNames.entries)
                            ButtonSegment(
                              value: entry.key,
                              label: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                        selected: {locale},
                        onSelectionChanged: (next) {
                          if (next.isEmpty) return;
                          localeNotifier.value = next.first;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: hapticsEnabledNotifier,
                builder: (_, enabled, __) => SettingsRow(
                  icon: Icons.vibration_outlined,
                  title: tr('haptics_title'),
                  trailing: Switch(
                    value: enabled,
                    onChanged: (v) => hapticsEnabledNotifier.value = v,
                  ),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: tr('set_profile'),
            children: [
              SettingsRow(
                icon: Icons.straighten_outlined,
                title: tr('unit_settings_title'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UnitSettingsScreen()),
                ),
              ),
              SettingsRow(
                icon: Icons.person_outline,
                title: tr('tab_mine'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyScreen()),
                ),
              ),
            ],
          ),
          SettingsGroup(
            title: tr('set_data'),
            children: [
              SettingsRow(
                icon: Icons.file_upload_outlined,
                title: tr('settings_export'),
                onTap: () => _exportData(context),
              ),
              SettingsRow(
                icon: Icons.move_to_inbox_outlined,
                title: tr('settings_import_title'),
                subtitle: tr('settings_import_subtitle'),
                onTap: () => _importData(context),
              ),
              const _ClearCacheTile(),
            ],
          ),
          SettingsGroup(
            title: tr('set_about'),
            children: [
              SettingsRow(
                icon: Icons.system_update_alt,
                title: tr('check_update'),
                subtitle: Platform.isIOS ? tr('ios_update_title') : null,
                onTap: () => _checkUpdate(context),
              ),
              SettingsRow(
                icon: Icons.apps_outlined,
                title: 'Ordnance',
                value:
                    '${tr('version_prefix')}v$appVersion${Platform.isIOS ? tr('version_suffix_ios') : tr('version_suffix')}',
              ),
              SettingsRow(
                icon: Icons.feedback_outlined,
                title: tr('feedback'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                ),
              ),
              SettingsRow(
                icon: Icons.person_add_outlined,
                title: tr('settings_invite'),
                onTap: () => _showInviteDialog(context),
              ),
              SettingsRow(
                icon: Icons.code,
                title: tr('about_github'),
                value: 'Toryphoto77/ordnance',
                onTap: () async {
                  final ok = await openSystemUrl(
                      'https://github.com/Toryphoto77/ordnance');
                  if (!ok && context.mounted) {
                    showAppToast(context, tr('browser_open_failed'));
                  }
                },
              ),
              SettingsRow(
                icon: Icons.book_outlined,
                title: tr('about_title'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
              SettingsRow(
                icon: Icons.bug_report_outlined,
                title: tr('app_log_title'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppLogScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// 从旧版导入：粘贴旧版「导出我的数据」的 JSON，
  /// 合并收藏、靶场成绩与经验。旧版签名不同无法覆盖升级，只能这样迁移。
  Future<void> _importData(BuildContext context) async {
    if (communityStore.current == null) {
      showAppToast(context, tr('settings_import_need_login'));
      return;
    }
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('settings_import_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('settings_import_note'),
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration:
                  InputDecoration(hintText: tr('settings_import_hint')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr('settings_import_action')),
          ),
        ],
      ),
    );
    final text = controller.text.trim();
    if (ok != true) return;
    int added;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      added = communityStore.importLegacyExport(decoded);
      if (decoded['app'] == 'Ordnance') {
        final tools = await mergeToolPayload(decoded);
        if (added == -2 && tools > 0) {
          if (context.mounted) {
            showAppToast(context, tr('settings_import_tools'));
          }
          return;
        }
        if (added >= 0) added += tools;
      }
    } catch (_) {
      if (context.mounted) showAppToast(context, tr('settings_import_bad'));
      return;
    }
    if (!context.mounted) return;
    if (added == -2) {
      showAppToast(context, tr('settings_import_need_login'));
    } else if (added < 0) {
      showAppToast(context, tr('settings_import_bad'));
    } else {
      showAppToast(context,
          '${tr('settings_import_done_prefix')}$added${tr('settings_import_done_suffix')}');
    }
  }

  /// 导出我的数据：与快捷操作面板里的“导出我的数据”共用同一份逻辑。
  Future<void> _exportData(BuildContext context) async {
    final me = communityStore.current;
    final profiles = await loadGunProfiles();
    final ammo = await loadAmmoItems();
    final sessions = await loadRangeSessions();
    final data = {
      'app': 'Ordnance',
      'version': appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      if (me != null) 'account': {
        'id': me.id,
        'nickname': me.nickname,
        'level': me.level,
        'totalXp': me.totalXp,
      },
      if (me != null) 'collection': me.collection.map((c) => c.toJson()).toList(),
      if (me != null) 'rangeScores': me.rangeScores.map((r) => r.toJson()).toList(),
      if (me != null)
        'earnedMedals':
            communityStore.earnedMedals(me).map((m) => m.id).toList(),
      'gunProfiles': profiles.map((p) => p.toJson()).toList(),
      'ammoItems': ammo.map((a) => a.toJson()).toList(),
      'rangeSessions': sessions.map((s) => s.toJson()).toList(),
    };
    try {
      const share = MethodChannel('gunsmap/share');
      final ok =
          await share.invokeMethod<bool>('shareText', {'text': jsonEncode(data)});
      if (ok != true && context.mounted) {
        showAppToast(context, tr('settings_share_failed'));
      }
    } catch (_) {
      if (context.mounted) showAppToast(context, tr('settings_export_failed'));
    }
  }

  /// 邀请好友：邀请码就是自己的 ID；新用户注册时填码，
  /// 邀请人在本机可直接 +100 经验，跨设备部分联网版按 invitedBy 结算。
  void _showInviteDialog(BuildContext context) {
    final me = communityStore.current;
    if (me == null) {
      showAppToast(context, tr('settings_login_invite'));
      return;
    }
    final invitedCount =
        communityStore.accounts.where((a) => a.invitedBy == me.id).length;
    const shareChannel = MethodChannel('gunsmap/share');
    showDialog(
      context: context,
      builder: (dialogContext) => GlassDialog(
        title: tr('settings_invite'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('settings_invite_code'), style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(me.id,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr('settings_invite_note'),
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(tr('settings_invite_count_prefix') + '$invitedCount' + tr('settings_invite_count_suffix'),
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: me.id));
              if (dialogContext.mounted) {
                showAppToast(dialogContext, tr('settings_invite_copied'));
              }
            },
            child: Text(tr('settings_copy_invite')),
          ),
          glassPrimaryButton(
            dialogContext,
            tr('settings_share_invite'),
            onPressed: () async {
              await shareChannel.invokeMethod('shareText', {
                'text':
                    '来玩 Ordnance，一起聊枪、晒收藏！下载：https://github.com/Toryphoto77/ordnance/releases/latest 邀请码：${me.id}（注册时填写）'
              });
            },
          ),
        ],
      ),
    );
  }

  /// 检查更新：只用 Dart 核心库查 GitHub 最新 Release，不引第三方包。
  /// iOS 版不走这条路：点开即提示走 TestFlight 更新，不查 Release、不下载。
  Future<void> _checkUpdate(BuildContext context) async {
    if (Platform.isIOS) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr('ios_update_title')),
          content: Text(tr('ios_update_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('ok')),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text(tr('checking')),
          ],
        ),
      ),
    );
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(Uri.parse(
          'https://api.github.com/repos/Toryphoto77/ordnance/releases/latest'));
      request.headers.set('Accept', 'application/vnd.github+json');
      request.headers.set('User-Agent', 'Ordnance');
      final response =
          await request.close().timeout(const Duration(seconds: 15));
      final body = await response.transform(utf8.decoder).join();
      client.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final tag = (data['tag_name'] as String?) ?? '';
      final latest = tag.replaceFirst(RegExp(r'^v'), '').split('-').first;
      final notes = (data['body'] as String?) ?? '';
      String? apkUrl;
      String? fallbackApk;
      for (final a in (data['assets'] as List? ?? [])) {
        final asset = a as Map;
        final name = (asset['name'] as String?) ?? '';
        if (!name.toLowerCase().endsWith('.apk')) continue;
        final url = asset['browser_download_url'] as String?;
        if (url == null) continue;
        fallbackApk ??= url;
        if (isOrdnanceApkName(name) && !name.toLowerCase().contains('debug')) {
          apkUrl = url;
          break;
        }
      }
      apkUrl ??= fallbackApk;
      final link =
          apkUrl ?? (data['html_url'] as String? ?? 'https://github.com/Toryphoto77/ordnance/releases');
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (latest.isEmpty || _compareVersions(latest, appVersion) <= 0) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('latest_title')),
            content: Text('${tr('latest_body_prefix')}$appVersion${tr('latest_body_suffix')}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('ok')),
              ),
            ],
          ),
        );
        return;
      }
      final shownNotes =
          notes.length > 500 ? '${notes.substring(0, 500)}…' : notes;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${tr('new_title_prefix')}$latest'),
          content: SingleChildScrollView(
            child: Text(shownNotes.isEmpty ? tr('new_empty') : shownNotes),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('close')),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!context.mounted) return;
                showAppToast(context, tr('copied'));
              },
              child: Text(tr('copy_link')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _downloadAndInstall(context, apkUrl ?? link, latest);
              },
              child: Text(tr('settings_download_install')),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr('check_failed')),
          content: Text(tr('check_failed_body')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('ok')),
            ),
          ],
        ),
      );
    }
  }

  /// 下载安装包并拉起系统安装器：只用 Dart 核心库下载到本机缓存，
  /// 再经 gunsmap/system 通道走 FileProvider 安装，不引第三方包。
  Future<void> _downloadAndInstall(
      BuildContext context, String apkUrl, String latest) async {
    if (Platform.isIOS) {
      // iOS 兜底：绝不调 installApk，统一提示走 TestFlight。
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(tr('ios_update_title')),
            content: Text(tr('ios_update_body')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('ok')),
              ),
            ],
          ),
        );
      }
      return;
    }
    if (!apkUrl.endsWith('.apk')) {
      if (context.mounted) {
        showAppToast(context, tr('settings_apk_missing'));
      }
      return;
    }
    final cacheDir =
        await getCacheDirPath() ?? Directory.systemTemp.path;
    final path = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DownloadDialog(url: apkUrl, version: latest, dir: cacheDir),
    );
    if (path == null) {
      if (context.mounted) {
        showAppToast(context, tr('settings_download_failed'));
      }
      return;
    }
    final ok = await installDownloadedApk(path);
    if (!context.mounted) return;
    showAppToast(context, ok
            ? tr('settings_installer_open')
            : tr('settings_installer_failed'), onTap: ok ? null : () => Clipboard.setData(ClipboardData(text: apkUrl)), actionLabel: ok ? null : tr('copy_link'));
  }

  /// 版本号比较：1.4.0 这种三段数字，返回负数表示 a 更旧。
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}

/// 清理缓存行：只删原生 cacheDir 下的临时文件（主要是更新时下载的安装包），
/// 绝不碰 SharedPreferences 里的账号、收藏柜、靶场成绩、弹药库存、保养记录、
/// 复装记录等本机数据；删完重新计算一次大小，副标题即刷新。
class _ClearCacheTile extends StatefulWidget {
  const _ClearCacheTile();

  @override
  State<_ClearCacheTile> createState() => _ClearCacheTileState();
}

class _ClearCacheTileState extends State<_ClearCacheTile> {
  int? _size;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _refreshSize();
  }

  Future<Directory?> _cacheDir() async {
    final path = await getCacheDirPath();
    if (path == null) return null;
    return Directory(path);
  }

  Future<int> _dirSize(Directory dir) async {
    var total = 0;
    try {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        try {
          if (e is File) total += await e.length();
        } catch (_) {}
      }
    } catch (_) {}
    return total;
  }

  Future<void> _refreshSize() async {
    final dir = await _cacheDir();
    final size = dir == null ? 0 : await _dirSize(dir);
    if (!mounted) return;
    setState(() => _size = size);
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _onTap() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => GlassDialog(
        title: tr('settings_clear_cache'),
        content: Text(tr('settings_clear_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('cancel')),
          ),
          glassPrimaryButton(ctx, tr('settings_clear_action'), popTrue: true),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _clearing = true);
    final dir = await _cacheDir();
    var freed = 0;
    if (dir != null) {
      freed = await _dirSize(dir);
      try {
        await for (final e in dir.list(followLinks: false)) {
          try {
            await e.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _clearing = false;
      _size = 0;
    });
    showAppToast(context,
        freed > 0 ? tr('settings_cleared_prefix') + _formatBytes(freed) : tr('settings_cache_empty'));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.cleaning_services_outlined, size: 22),
      title: Text(tr('settings_clear_cache')),
      subtitle: Text(_clearing
          ? tr('settings_clearing')
          : _size == null
              ? tr('settings_calculating')
              : tr('settings_cache_now_prefix') + _formatBytes(_size!) + tr('settings_cache_now_suffix')),
      onTap: _clearing ? null : _onTap,
    );
  }
}

/// 下载进度对话框：弹出即开始下载，完成后带文件路径退出，失败带 null 退出。
class _DownloadDialog extends StatefulWidget {
  final String url;
  final String version;
  final String dir;
  const _DownloadDialog(
      {required this.url, required this.version, required this.dir});

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(widget.url));
      request.headers.set('User-Agent', 'Ordnance');
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength;
      final name = ordnanceApkFileName(
        version: widget.version,
        contentDisposition: response.headers.value('content-disposition'),
      );
      final file = File('${widget.dir}/$name');
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (mounted && total > 0) {
          setState(() => _progress = received / total);
        }
      }
      await sink.close();
      client.close();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('settings_downloading')),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null),
                const SizedBox(height: 4),
                Text(_progress > 0
                    ? '${(_progress * 100).toStringAsFixed(0)}%'
                    : '…'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

