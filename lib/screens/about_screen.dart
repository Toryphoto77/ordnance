import 'dart:io';
import '../i18n.dart';
import '../data.dart';

import 'package:flutter/material.dart';
import '../widgets/app_toast.dart';
import '../system_actions.dart';
import '../widgets/app_top_bar.dart';

/// 项目手册：Ordnance 是什么、能干什么、每块怎么用。
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _section(String title, List<String> lines, Color grey,
      {IconData icon = Icons.info_outlined}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Text(lines[i], style: const TextStyle(fontSize: 14)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// 数据概况：数字直接取自数据集，避免文案与数据脱节。
  Widget _dataOverviewCard(Color grey) {
    final items = <List<String>>[
      ['${guns.length}', tr('about_data_guns')],
      ['${accessories.length}', tr('about_data_accessories')],
      ['${caliberInfos.length}', tr('about_data_calibers')],
      ['${legends.length}', tr('about_data_legends')],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dataset_outlined, size: 22),
            const SizedBox(width: 8),
            Text(tr('about_data_title'),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: Column(
                      children: [
                        Text(item[0],
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(item[1],
                            style: TextStyle(color: grey, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final grey = dark ? const Color(0xFF8A8578) : const Color(0xFF9A917F);
    return Scaffold(
      appBar: SubPageAppBar(title: tr('about_title')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(tr('about_intro'), [
            tr('about_tool_1'),
            tr('about_tool_2'),
            tr('about_tool_3'),
            tr('about_tool_4'),
            tr('about_tool_5'),
          ], grey, icon: Icons.info_outlined),
          _dataOverviewCard(grey),
          _section(tr('about_manual_catalog'), [
            tr('about_tool_2'),
            tr('detail_add_armory'),
            tr('detail_maint'),
          ], grey, icon: Icons.grid_view_rounded),
          _section(tr('about_manual_reload'), [
            tr('about_tool_4'),
            tr('load_caution'),
          ], grey, icon: Icons.handyman_outlined),
          _section(tr('about_manual_community'), [
            tr('community_guidelines_body'),
          ], grey, icon: Icons.forum_outlined),
          _section(tr('about_manual_update'), [
            if (!Platform.isIOS)
              '设置页 → 检查更新：有新版时可直接下载安装包并拉起系统安装器安装（需在系统设置中允许本应用安装未知应用）。',
            '设置页 → 清理缓存：只删临时文件（含已下载的安装包），账号、靶场成绩、弹药库存、保养与复装记录等本机数据不会被删除。',
            '设置页顶部有快捷操作面板：检查更新、清理缓存、导出我的数据都在上面。',
            tr('about_hist_01'),
            tr('about_hist_02'),
            tr('about_hist_03'),
            tr('about_hist_04'),
            tr('about_hist_05'),
            tr('about_hist_06'),
            tr('about_hist_07'),
            tr('about_hist_08'),
            tr('about_hist_09'),
            tr('about_hist_10'),
            tr('about_hist_11'),
            tr('about_hist_12'),
            tr('about_hist_13'),
            tr('about_hist_14'),
            tr('about_hist_15'),
            tr('about_hist_16'),
            tr('about_hist_17'),
            tr('about_hist_18'),
            tr('about_hist_19'),
            tr('about_hist_20'),
            tr('about_hist_21'),
            tr('about_hist_22'),
            tr('about_hist_23'),
            tr('about_hist_24'),
            tr('about_hist_25'),
            tr('about_hist_26'),
            tr('about_hist_27'),
            tr('about_hist_28'),
            tr('about_hist_29'),
            tr('about_hist_30'),
            tr('about_hist_31'),
            tr('about_hist_32'),
            tr('about_hist_33'),
            tr('about_hist_34'),
            tr('about_hist_35'),
            tr('about_hist_36'),
            tr('about_hist_37'),
            tr('about_hist_38'),
            tr('about_hist_39'),
          ], grey, icon: Icons.system_update_alt),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code, size: 22),
              title: Text(tr('about_github')),
              subtitle: const Text('Toryphoto77/ordnance'),
              onTap: () async {
                final ok = await openSystemUrl(
                    'https://github.com/Toryphoto77/ordnance');
                if (!ok && context.mounted) {
                  showAppToast(context, tr('browser_open_failed'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
