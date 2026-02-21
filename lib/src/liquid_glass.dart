import 'dart:ui';
import 'package:flutter/material.dart';

/// Defines the visual variant of the Liquid Glass material.
enum GlassVariant {
  /// Versatile, highly adaptive. Standard for toolbars, buttons.
  /// Applies strong lensing (blur) and adaptive lighting.
  regular,

  /// High transparency. Used over visually rich backgrounds.
  /// Lower blur, allowing background details to show clearly.
  clear,

  /// Disables the effect. Used for conditional toggling (state management).
  identity,
}

/// Configuration for the Liquid Glass effect properties.
/// Mirrors `Glass` in SwiftUI, enhanced with Deep Research optics.
class Glass {
  final GlassVariant variant;
  final Color tintColor;
  final bool isInteractive;

  const Glass._({
    this.variant = GlassVariant.regular,
    this.tintColor = Colors.transparent,
    this.isInteractive = false,
  });

  /// The regular Liquid Glass material.
  static const Glass regular = Glass._(variant: GlassVariant.regular);

  /// The clear Liquid Glass material.
  static const Glass clear = Glass._(variant: GlassVariant.clear);

  /// The identity (disabled) Liquid Glass material.
  static const Glass identity = Glass._(variant: GlassVariant.identity);

  /// Applies a tint color to the glass material (Illumination Layer / Color Spill).
  Glass tint(Color color) {
    return Glass._(
      variant: variant,
      tintColor: color,
      isInteractive: isInteractive,
    );
  }

  /// Makes the glass material reactive to touch interactions (Fluidity).
  Glass interactive([bool value = true]) {
    return Glass._(
      variant: variant,
      tintColor: tintColor,
      isInteractive: value,
    );
  }
}

extension LiquidGlassExtension on Widget {
  /// Applies an advanced Liquid Glass effect to the view.
  ///
  /// Optionally takes a [Glass] configuration and an [inShape].
  /// Example:
  /// ```dart
  /// Text("Hello").glassEffect();
  /// Text("Action").glassEffect(Glass.regular.tint(Colors.blue).interactive());
  /// ```
  Widget glassEffect([Glass glass = Glass.regular, ShapeBorder? inShape]) {
    if (glass.variant == GlassVariant.identity) {
      return this;
    }

    return _LiquidGlass(
      shape: inShape ?? const StadiumBorder(),
      glass: glass,
      child: this,
    );
  }

  /// Identifies the widget for morphing in transitions.
  Widget glassEffectID(String id, String namespace) {
    return Hero(tag: '$namespace/$id', child: this);
  }

  /// Specifies a view contributes to a unified effect with a particular ID.
  Widget glassEffectUnion({required String id, required String namespace}) {
    return MetaData(metaData: 'glassEffectUnion:$namespace/$id', child: this);
  }
}

class _LiquidGlass extends StatefulWidget {
  final ShapeBorder shape;
  final Glass glass;
  final Widget child;

  const _LiquidGlass({
    required this.shape,
    required this.glass,
    required this.child,
  });

  @override
  State<_LiquidGlass> createState() => _LiquidGlassState();
}

class _LiquidGlassState extends State<_LiquidGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fluidityAnimation; // Controls elasticity/scale
  late Animation<double> _highlightAnimation; // Controls specular reaction

  @override
  void initState() {
    super.initState();
    // Fluidity: mimic gel-like elasticity (魔法の操作感)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 400),
    );

    _fluidityAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const ElasticOutCurve(0.8),
        reverseCurve: Curves.easeOutCubic,
      ),
    );

    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCirc));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.glass.isInteractive) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.glass.isInteractive) _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.glass.isInteractive) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _fluidityAnimation.value;
        final highlight = _highlightAnimation.value;

        // Visual specifications based on variant
        final bool isRegular = widget.glass.variant == GlassVariant.regular;
        final double blurAmount = isRegular ? 40.0 : 15.0;
        final double baseWhiteAlpha = isRegular ? 0.08 : 0.02;

        // Tint / Illumination alpha
        final double tintAlpha = widget.glass.tintColor.a == 0.0
            ? 0.0
            : widget.glass.tintColor.a;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: widget.glass.isInteractive ? _handleTapDown : null,
            onTapUp: widget.glass.isInteractive ? _handleTapUp : null,
            onTapCancel: widget.glass.isInteractive ? _handleTapCancel : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                // 1. Shadow Layer (Depth & spatial separation)
                // Painted via CustomPaint to respect ShapeBorder outsets
                CustomPaint(
                  painter: _GlassShadowPainter(
                    shape: widget.shape,
                    shadowColor: Colors.black.withAlpha(
                      ((0.15 + highlight * 0.05) * 255).round(),
                    ),
                    elevation: 12.0 - (highlight * 4.0),
                  ),
                ),

                // Clip layer for optical refractions and materials
                ClipPath(
                  clipper: ShapeBorderClipper(shape: widget.shape),
                  child: Stack(
                    fit: StackFit.passthrough,
                    children: [
                      // 2. Refraction Layer (Lensing)
                      // distorts background pixels
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: blurAmount,
                          sigmaY: blurAmount,
                        ),
                        child: const SizedBox.shrink(),
                      ),

                      // 3. Illumination Layer (Color spill & soft filling)
                      Container(
                        decoration: ShapeDecoration(
                          shape: widget.shape,
                          color: widget.glass.tintColor.withAlpha(
                            ((tintAlpha + highlight * 0.1).clamp(0.0, 1.0) *
                                    255)
                                .round(),
                          ),
                        ),
                      ),

                      // 4. Highlight Layer (Specular Highlights & Environment Reflection)
                      Container(
                        decoration: ShapeDecoration(
                          shape: widget.shape,
                          color: Colors.white.withAlpha(
                            (baseWhiteAlpha * 255).round(),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withAlpha(
                                ((0.3 + highlight * 0.4).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ),
                              Colors.white.withAlpha(
                                ((0.05 + highlight * 0.1).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ),
                              Colors.transparent,
                              Colors.white.withAlpha(
                                ((0.1 + highlight * 0.2).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ),
                            ],
                            stops: const [0.0, 0.4, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Dispersion Layer (Chromatic Aberration / Luminous Edge)
                // Painted over the clipped glass to give multi-color rim light
                CustomPaint(
                  foregroundPainter: _LiquidDispersionPainter(
                    shape: widget.shape,
                    highlightPhase: highlight,
                  ),
                  child: widget.child,
                ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    ); // <- widget.child mapped here safely
  }
}

/// Renders a dynamic depth shadow matching the shape without filling the core.
class _GlassShadowPainter extends CustomPainter {
  final ShapeBorder shape;
  final Color shadowColor;
  final double elevation;

  _GlassShadowPainter({
    required this.shape,
    required this.shadowColor,
    required this.elevation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation <= 0) return;
    final rect = Offset.zero & size;
    final path = shape.getOuterPath(rect);

    canvas.drawShadow(path, shadowColor, elevation, false);
  }

  @override
  bool shouldRepaint(covariant _GlassShadowPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.elevation != elevation;
  }
}

/// Renders the Dispersion (Chromatic Aberration) and luminous edge.
class _LiquidDispersionPainter extends CustomPainter {
  final ShapeBorder shape;
  final double highlightPhase;

  _LiquidDispersionPainter({required this.shape, required this.highlightPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect);

    // Multi-pass stroke to create subtle chromatic dispersion
    // Red channel
    _drawStroke(
      canvas,
      path,
      const Color(0x33FF6B6B),
      1.5 + highlightPhase * 0.5,
      const Offset(0.5, 0.5),
    );
    // Blue channel
    _drawStroke(
      canvas,
      path,
      const Color(0x334ECDC4),
      1.5 + highlightPhase * 0.5,
      const Offset(-0.5, -0.5),
    );
    // Core white rim
    _drawStroke(
      canvas,
      path,
      Colors.white.withAlpha(
        ((0.4 + highlightPhase * 0.4).clamp(0.0, 1.0) * 255).round(),
      ),
      1.0 + highlightPhase,
      Offset.zero,
    );
  }

  void _drawStroke(
    Canvas canvas,
    Path path,
    Color color,
    double width,
    Offset offset,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;

    if (offset != Offset.zero) {
      canvas.save();
      canvas.translate(offset.dx, offset.dy);
      canvas.drawPath(path, paint);
      canvas.restore();
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidDispersionPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.highlightPhase != highlightPhase;
  }
}
