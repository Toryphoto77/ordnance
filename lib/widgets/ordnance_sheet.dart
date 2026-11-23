import 'package:flutter/material.dart';

import '../design/ordnance_tokens.dart';

/// Modal sheet with the shared top radius, drag handle, and keyboard inset.
/// Forms that used to pop up as a floating dialog use this instead.
Future<T?> showOrdnanceSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final inset = MediaQuery.viewInsetsOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(
            OrdnanceSpace.lg, 0, OrdnanceSpace.lg, OrdnanceSpace.lg + inset),
        child: builder(ctx),
      );
    },
  );
}
