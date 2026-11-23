import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 震动反馈开关：设置页写入，各卡片点击与底部导航切换时读取。
/// 与主题一样，仅本次打开期间生效，不做持久化。
final ValueNotifier<bool> hapticsEnabledNotifier = ValueNotifier(true);

int _lastHapticMs = 0;

/// Light tick for buttons, list rows, chips, and the nav bar.
/// Debounced so a control that both splashes and calls this does not
/// double-fire.
void tapHaptic() {
  if (!hapticsEnabledNotifier.value) return;
  final now = DateTime.now().millisecondsSinceEpoch;
  if (now - _lastHapticMs < 40) return;
  _lastHapticMs = now;
  HapticFeedback.selectionClick();
}
