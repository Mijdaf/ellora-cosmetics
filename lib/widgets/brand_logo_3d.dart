import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays your real uploaded logo (assets/images/logo.png), floating and
/// tilting in 3D space via a perspective transform matrix — reacts to both
/// an idle auto-sway and the cursor position.
class BrandLogo3D extends StatefulWidget {
  final double size;
  const BrandLogo3D({super.key, this.size = 220});

  @override
  State<BrandLogo3D> createState() => _BrandLogo3DState();
}

class _BrandLogo3DState extends State<BrandLogo3D> with TickerProviderStateMixin {
  late final AnimationController _controller; // idle float + 3D tilt
  late final AnimationController _entrance; // one-shot pop-in on first build
  late final AnimationController _shine; // periodic diagonal light sweep
  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(period: const Duration(milliseconds: 3600));
  }

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(e.position);
        setState(() {
          _pointer = Offset(
            (local.dx / box.size.width * 2 - 1).clamp(-1, 1),
            (local.dy / box.size.height * 2 - 1).clamp(-1, 1),
          );
        });
      },
      onExit: (_) => setState(() => _pointer = Offset.zero),
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _entrance]),
        builder: (context, child) {
          final autoSwing = math.sin(_controller.value * 2 * math.pi) * 0.10;
          final rotY = autoSwing + (_pointer.dx * 0.35);
          final rotX = _pointer.dy * -0.22;
          final floatY = math.sin(_controller.value * 2 * math.pi) * 8;

          // Entrance: pop in with a slight overshoot scale + fade + rise,
          // instead of just appearing flat when the hero first mounts.
          final entranceT = Curves.easeOutBack.transform(_entrance.value);
          final entranceOpacity = Curves.easeOut.transform(_entrance.value).clamp(0.0, 1.0);
          final entranceRise = (1 - Curves.easeOut.transform(_entrance.value)) * 40;

          return Opacity(
            opacity: entranceOpacity,
            child: Transform.translate(
              offset: Offset(0, floatY + entranceRise),
              child: Transform.scale(
                scale: 0.85 + entranceT * 0.15,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateX(rotX)
                      ..rotateY(rotY),
                    child: child,
                  ),
                ),
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _shine,
          builder: (context, child) => _Shine(progress: _shine.value, child: child!),
          child: _LogoImage(size: widget.size),
        ),
      ),
    );
  }
}

/// Wraps the logo with a diagonal light-band that sweeps across it every
/// few seconds, giving the glossy pink mark a periodic "shimmer" — a subtle
/// premium touch rather than a static, lifeless image.
class _Shine extends StatelessWidget {
  final double progress; // 0..1, looping
  final Widget child;
  const _Shine({required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        // Sweep band travels from before the left edge to past the right
        // edge, then the controller loops with a pause built into its
        // period so the shine doesn't feel constant/nervous.
        final band = 0.28;
        final start = (progress * (1 + band * 2)) - band;
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [Colors.transparent, Colors.white70, Colors.transparent],
          stops: [
            (start - band).clamp(0.0, 1.0),
            start.clamp(0.0, 1.0),
            (start + band).clamp(0.0, 1.0),
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

class _LogoImage extends StatelessWidget {
  final double size;
  const _LogoImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.espressoDeep,
          alignment: Alignment.center,
          child: const Icon(Icons.spa, color: AppColors.wheatGold, size: 60),
        ),
      ),
    );
  }
}
