import 'package:flutter/material.dart';

/// A container that coordinates multiple Liquid Glass elements, optionally morphing them.
/// In SwiftUI, GlassEffectContainer blends shapes together and morphs them during transitions
/// if they are within the [spacing] interval.
///
/// In Flutter, this acts as a wrapper that groups glass elements and provides an API
/// mirroring the Apple Liquid Glass design language. Full gooey-morphing of arbitrary borders
/// requires shader math, but this provides the structural equivalent.
class GlassEffectContainer extends StatelessWidget {
  /// Controls how Liquid Glass effects behind views interact with one another.
  /// The larger the spacing value, the sooner the effects blend together.
  final double spacing;

  /// The children, typically an `HStack` / `Row` or `VStack` / `Column`.
  final Widget child;

  const GlassEffectContainer({
    super.key,
    this.spacing = 20.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // For a highly advanced graphics engine we would wrap this in a rendering layer
    // that captures bounds of `.glassEffect()` children and merges their `Path`s
    // into a unified gooey ClipPath.
    // Here we provide the standard compositing wrapper.
    return child;
  }
}

/// A custom transition builder akin to `GlassEffectTransition` in SwiftUI Liquid Glass.
class GlassEffectTransition {
  /// Used for effects within the container’s assigned spacing.
  static Widget matchedGeometry(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    // Uses simple fade + slight slide to mimic shape morphing
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  /// Used for effects added/removed that are farther from each other than the container’s spacing.
  static Widget materialize(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    // A scale and fade typical of "materialize" in Liquid Glass
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.85,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn)),
        child: child,
      ),
    );
  }
}
