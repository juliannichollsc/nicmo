import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const Duration _forward = Duration(milliseconds: 520);
const Duration _reverse = Duration(milliseconds: 380);

/// Material 3 "emphasized" easing: quick start, long gentle settle.
const Curve _emphasized = Curves.easeInOutCubicEmphasized;

/// Horizontal shared-axis: the new page slides in while the old one slides
/// out and fades, like a train leaving the platform.
CustomTransitionPage<void> sharedAxisPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _forward,
    reverseTransitionDuration: _reverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _SharedAxis(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
  );
}

/// Fade-through with a subtle zoom; used when entering the main shell.
CustomTransitionPage<void> fadeThroughPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: _forward,
    reverseTransitionDuration: _reverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: _emphasized,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.15, 0.8, curve: Curves.easeOut),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Bottom-up reveal for full screen flows such as an active trip.
CustomTransitionPage<void> slideUpPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 550),
    reverseTransitionDuration: _reverse,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

class _SharedAxis extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  const _SharedAxis({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final incoming = CurvedAnimation(
      parent: animation,
      curve: _emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: _emphasized,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.35, 0),
        end: Offset.zero,
      ).animate(incoming),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
        ),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.25, 0),
          ).animate(outgoing),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1, end: 0).animate(
              CurvedAnimation(
                parent: secondaryAnimation,
                curve: const Interval(0, 0.6, curve: Curves.easeIn),
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.94).animate(outgoing),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetroPageTransitionsBuilder extends PageTransitionsBuilder {
  const _MetroPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _SharedAxis(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Applied to every MaterialPageRoute (dialog-like pages pushed imperatively).
const PageTransitionsTheme metroPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _MetroPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: _MetroPageTransitionsBuilder(),
    TargetPlatform.macOS: _MetroPageTransitionsBuilder(),
    TargetPlatform.windows: _MetroPageTransitionsBuilder(),
  },
);

/// Animates switches between the shell branches (home / settings)
/// while keeping every branch alive, as `indexedStack` does.
class AnimatedBranchContainer extends StatelessWidget {
  final int currentIndex;
  final List<Widget> children;

  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          _BranchLayer(
            active: i == currentIndex,
            direction: i < currentIndex ? -1 : 1,
            child: children[i],
          ),
      ],
    );
  }
}

class _BranchLayer extends StatelessWidget {
  final bool active;
  final int direction;
  final Widget child;

  const _BranchLayer({
    required this.active,
    required this.direction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 480);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: AnimatedSlide(
          offset: active ? Offset.zero : Offset(0.3 * direction, 0),
          duration: duration,
          curve: _emphasized,
          child: AnimatedScale(
            scale: active ? 1 : 0.94,
            duration: duration,
            curve: _emphasized,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: Duration(milliseconds: active ? 360 : 220),
              curve: Curves.easeOut,
              // Inactive branches keep their state but stop animating.
              child: TickerMode(enabled: active, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
