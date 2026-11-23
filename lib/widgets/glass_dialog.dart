import 'dart:ui';
import 'package:flutter/material.dart';

/// 全 App 输入类子窗口的统一风格：毛玻璃圆角卡片 + 铜色主按钮。
/// 与账号弹窗（登录/注册/编辑资料）同款视觉语言：深色毛玻璃底、
/// 28 圆角、标题 + 内容 + 底部按钮行。
class GlassDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget> actions;
  const GlassDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              color: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close,
                                size: 20,
                                color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 16),
                    content,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 毛玻璃弹窗里的标准按钮：次按钮文字、主按钮铜色实心。
Widget glassCancelButton(BuildContext context, String label) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(false),
    child: Text(label),
  );
}

Widget glassPrimaryButton(BuildContext context, String label,
    {VoidCallback? onPressed, bool popTrue = false}) {
  // 以前没传 onPressed 且 popTrue 为 false 时 onPressed 是 null，
  // 按钮会直接变灰禁用（等级/身份弹窗的“知道了”就是这么坏的）。
  // 现在默认就是关弹窗，popTrue 时带回 true。
  return FilledButton(
    onPressed: onPressed ??
        () => Navigator.of(context).pop(popTrue ? true : null),
    child: Text(label),
  );
}
