import 'package:flutter/material.dart';

import '../design/ordnance_tokens.dart';

/// Shared-axis transition on the horizontal axis: the incoming page
/// fades and slides in a short distance while the outgoing page eases
/// aside. Same builder for every platform so pushes feel consistent.
class SharedAxisPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enter = CurvedAnimation(
        parent: animation, curve: OrdnanceMotion.emphasized);
    final exit = CurvedAnimation(
        parent: secondaryAnimation, curve: OrdnanceMotion.emphasized);
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.4).animate(exit),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.04, 0),
        ).animate(exit),
        child: FadeTransition(
          opacity: enter,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(enter),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Fade-through for bottom-nav switches. The outgoing page leaves first;
/// the incoming page fades up from a slight scale so the change reads as
/// one motion instead of a cross-fade blink.
class FadeThroughSwitcher extends StatelessWidget {
  final Widget child;
  const FadeThroughSwitcher({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: OrdnanceMotion.fadeThrough,
      switchInCurve: OrdnanceMotion.enter,
      switchOutCurve: OrdnanceMotion.exit,
      layoutBuilder: (current, previous) {
        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.topCenter,
          children: [
            ...previous,
            if (current != null) current,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1, curve: OrdnanceMotion.emphasized),
        );
        final scale = Tween<double>(begin: 0.98, end: 1).animate(fade);
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
