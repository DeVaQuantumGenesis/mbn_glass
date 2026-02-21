import 'dart:ui';
import 'package:flutter/material.dart';

/// Configuration for the Liquid Glass effect properties.
/// Mirrors `Glass` in SwiftUI.
class Glass {
  final Color tintColor;
  final bool isInteractive;
  final double blurX;
  final double blurY;

  const Glass._({
    this.tintColor = Colors.transparent,
    this.isInteractive = false,
    this.blurX = 30.0,
    this.blurY = 30.0,
  });

  /// The regular Liquid Glass material.
  static const Glass regular = Glass._(blurX: 30.0, blurY: 30.0);

  /// A thicker Liquid Glass material with more blur.
  static const Glass thick = Glass._(blurX: 50.0, blurY: 50.0);

  /// A thinner Liquid Glass material with less blur.
  static const Glass thin = Glass._(blurX: 15.0, blurY: 15.0);

  /// Applies a tint color to the glass material.
  Glass tint(Color color) {
    return Glass._(
      tintColor: color,
      isInteractive: isInteractive,
      blurX: blurX,
      blurY: blurY,
    );
  }

  /// Makes the glass material reactive to touch interactions.
  Glass interactive([bool value = true]) {
    return Glass._(
      tintColor: tintColor,
      isInteractive: value,
      blurX: blurX,
      blurY: blurY,
    );
  }
}

extension LiquidGlassExtension on Widget {
  /// Applies a Liquid Glass effect to the view.
  ///
  /// Optionally takes a [Glass] configuration and an [inShape].
  /// Example:
  /// ```dart
  /// Text("Hello").glassEffect();
  /// Text("Hello").glassEffect(Glass.regular.tint(Colors.orange).interactive());
  /// Text("Hello").glassEffect(inShape: RoundedRectangleBorder(...));
  /// ```
  Widget glassEffect([Glass glass = Glass.regular, ShapeBorder? inShape]) {
    return _LiquidGlass(
      shape: inShape ?? const StadiumBorder(),
      tint: glass.tintColor,
      blurX: glass.blurX,
      blurY: glass.blurY,
      interactive: glass.isInteractive,
      child: this,
    );
  }

  /// Identifies the widget for morphing in transitions, similar to SwiftUI's `glassEffectID`.
  /// Uses Flutter's [Hero] logic under the hood to transition states.
  Widget glassEffectID(String id, String namespace) {
    return Hero(tag: '$namespace/$id', child: this);
  }

  /// Specifies a view contributes to a unified effect with a particular ID.
  /// Combines geometries for unioned containers.
  Widget glassEffectUnion({required String id, required String namespace}) {
    return MetaData(metaData: 'glassEffectUnion:$namespace/$id', child: this);
  }
}

class _LiquidGlass extends StatefulWidget {
  final ShapeBorder shape;
  final Color tint;
  final double blurX;
  final double blurY;
  final bool interactive;
  final Widget child;

  const _LiquidGlass({
    required this.shape,
    required this.tint,
    required this.blurX,
    required this.blurY,
    required this.interactive,
    required this.child,
  });

  @override
  State<_LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<_LiquidGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 250),
    );
    // Subtle morphing/scaling typical of Liquid Glass interactivity
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    // Reactive glow or tinting
    _glowAnimation = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.interactive) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.interactive) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.interactive) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final glow = _glowAnimation.value;

        // Base opacity logic for the tint. Use .a to fetch alpha directly.
        final double baseAlpha = widget.tint.a == 0.0 ? 0.0 : widget.tint.a;
        final double highlightAlpha = 0.35 + glow * 2;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: widget.interactive ? _handleTapDown : null,
            onTapUp: widget.interactive ? _handleTapUp : null,
            onTapCancel: widget.interactive ? _handleTapCancel : null,
            behavior: HitTestBehavior.opaque,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: widget.shape),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  // 1. Frosted Glass Blur Backdrop
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurX,
                      sigmaY: widget.blurY,
                    ),
                    child: const SizedBox.shrink(),
                  ),

                  // 2. Liquid Glass Material Colors & Gradient
                  Container(
                    decoration: ShapeDecoration(
                      shape: widget.shape,
                      color: widget.tint.withAlpha(
                        ((baseAlpha + glow).clamp(0.0, 1.0) * 255).round(),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withAlpha(
                            ((highlightAlpha).clamp(0.0, 1.0) * 255).round(),
                          ),
                          Colors.white.withAlpha(
                            ((0.1 + glow).clamp(0.0, 1.0) * 255).round(),
                          ),
                          Colors.transparent,
                          Colors.white.withAlpha(
                            ((0.15 + glow * 0.5).clamp(0.0, 1.0) * 255).round(),
                          ),
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // 3. Inner Stroke (Specular Highlight / Luminous Edges) & Content
                  CustomPaint(
                    foregroundPainter: _GlassBorderPainter(
                      shape: widget.shape,
                      color: Colors.white.withAlpha(
                        ((0.4 + glow).clamp(0.0, 1.0) * 255).round(),
                      ),
                      width: 1.0 + (glow * 2), // thickens slightly on press
                    ),
                    child: child!,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: content,
    );
  }
}

class _GlassBorderPainter extends CustomPainter {
  final ShapeBorder shape;
  final Color color;
  final double width;

  _GlassBorderPainter({
    required this.shape,
    required this.color,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.width != width;
  }
}
