import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Motion-inspired Animation Card Component (motion.dev / Framer Motion equivalent in Flutter).
/// 
/// Fitur:
/// 1. Animasi Masuk (Entrance Animation): Staggered fade in, slide up lembut, dan scale-in halus.
/// 2. Efek Hover: Transform translateY ke atas (-3.5px) saat pointer kursor berada di atas card.
/// 3. Efek Tap/Click: Micro-scale down lembut saat card ditekan.
class MotionCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? delay;
  final Duration duration;
  final bool enableHover;
  final double hoverOffsetY;
  final VoidCallback? onTap;

  const MotionCard({
    super.key,
    required this.child,
    this.index = 0,
    this.delay,
    this.duration = const Duration(milliseconds: 380),
    this.enableHover = true,
    this.hoverOffsetY = -3.5,
    this.onTap,
  });

  @override
  State<MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends State<MotionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDelay = widget.delay ??
        Duration(milliseconds: (widget.index * 70).clamp(0, 450));

    Widget content = widget.child;

    if (widget.enableHover) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(
                0.0,
                _isPressed ? 1.0 : (_isHovered ? widget.hoverOffsetY : 0.0),
              )
              ..scale(_isPressed ? 0.985 : 1.0),
            child: widget.child,
          ),
        ),
      );
    } else if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content
        .animate(delay: effectiveDelay)
        .fadeIn(duration: widget.duration, curve: Curves.easeOutCubic)
        .slideY(
          begin: 0.08,
          end: 0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
        )
        .scaleXY(
          begin: 0.985,
          end: 1.0,
          duration: widget.duration,
          curve: Curves.easeOutCubic,
        );
  }
}
