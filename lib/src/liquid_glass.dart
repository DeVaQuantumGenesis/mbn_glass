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
        final double lensScale = isRegular
            ? 1.05
            : 1.01; // REAL Lensing magnification factor!
        final double baseWhiteAlpha = isRegular ? 0.05 : 0.01;

        // Tint / Illumination alpha
        final double tintAlpha = widget.glass.tintColor.a == 0.0
            ? 0.0
            : widget.glass.tintColor.a;

        // Precompute lens matrix for refraction
        final Matrix4 lensMatrix = Matrix4.identity()
          ..scale(lensScale, lensScale);

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
                      // 2. TRUE Refraction Layer (Lensing = Blur + Magnification)
                      // This bends the view BEHIND the glass, acting like a real lens.
                      BackdropFilter(
                        filter: ImageFilter.compose(
                          outer: ImageFilter.blur(
                            sigmaX: blurAmount,
                            sigmaY: blurAmount,
                          ),
                          inner: ImageFilter.matrix(lensMatrix.storage),
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

                      // 4. Highlight Layer (Volumetric Specular Highlights & Environment Reflection)
                      // Simulated using a dynamic linear gradient that catches light strongly on top-left.
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
                                ((0.4 + highlight * 0.5).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ), // Strong top-left reflection
                              Colors.white.withAlpha(
                                ((0.05 + highlight * 0.2).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ),
                              Colors.transparent,
                              Colors.black.withAlpha(
                                ((0.05).clamp(0.0, 1.0) * 255).round(),
                              ), // Depth shading on bottom right
                              Colors.white.withAlpha(
                                ((0.15 + highlight * 0.2).clamp(0.0, 1.0) * 255)
                                    .round(),
                              ), // Small bottom rim light
                            ],
                            stops: const [0.0, 0.25, 0.6, 0.8, 1.0],
                          ),
                        ),
                      ),

                      // Glare overlay to give volumetric thickness (Apple's top inner bevel reflection)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GlassGlarePainter(
                            shape: widget.shape,
                            highlightPhase: highlight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Dispersion Layer (Chromatic Aberration / Asymmetric Luminous Edge)
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

/// Renders a soft radial glare on the top-left to simulate volumetric glass curvature
class _GlassGlarePainter extends CustomPainter {
  final ShapeBorder shape;
  final double highlightPhase;

  _GlassGlarePainter({required this.shape, required this.highlightPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect);

    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.6),
        radius: 0.8 + (highlightPhase * 0.2),
        colors: [
          Colors.white.withAlpha(
            ((0.15 + highlightPhase * 0.15) * 255).round(),
          ),
          Colors.transparent,
        ],
      ).createShader(rect);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GlassGlarePainter oldDelegate) =>
      oldDelegate.highlightPhase != highlightPhase ||
      oldDelegate.shape != shape;
}

/// Renders the Dispersion (Chromatic Aberration) and luminous asymmetric edge.
class _LiquidDispersionPainter extends CustomPainter {
  final ShapeBorder shape;
  final double highlightPhase;

  _LiquidDispersionPainter({required this.shape, required this.highlightPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect);

    // Multi-pass stroke to create subtle chromatic dispersion
    _drawStroke(
      canvas,
      path,
      const Color(0x33FF6B6B), // Red
      1.5 + highlightPhase * 0.5,
      const Offset(0.3, 0.3),
    );
    _drawStroke(
      canvas,
      path,
      const Color(0x334ECDC4), // Cyan
      1.5 + highlightPhase * 0.5,
      const Offset(-0.3, -0.3),
    );

    // To mirror the WWDC Control Center glass, the edge isn't uniform.
    // Top and Left edges are thick and bright (catching the light), Bottom and Right are subtle.
    // We achieve this with a LinearGradient stroke on the path.
    final edgePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(
            ((0.75 + highlightPhase * 0.25).clamp(0.0, 1.0) * 255).round(),
          ), // Bright top-left specular
          Colors.white.withAlpha(
            ((0.15 + highlightPhase * 0.1).clamp(0.0, 1.0) * 255).round(),
          ), // Subtle core
          Colors.white.withAlpha(0), // Fade out
          Colors.white.withAlpha(
            ((0.3 + highlightPhase * 0.2).clamp(0.0, 1.0) * 255).round(),
          ), // Slight rim light on bottom right
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(rect)
      ..strokeWidth = 1.0 + (highlightPhase * 1.5)
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, edgePaint);
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
