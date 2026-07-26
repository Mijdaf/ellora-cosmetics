import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays your real uploaded logo (assets/images/logo.jpg), floating and
/// tilting in 3D space via a perspective transform matrix — reacts to both
/// an idle auto-sway and the cursor position.
class WheatLogo3D extends StatefulWidget {
  final double size;
  const WheatLogo3D({super.key, this.size = 220});

  @override
  State<WheatLogo3D> createState() => _WheatLogo3DState();
}

class _WheatLogo3DState extends State<WheatLogo3D> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
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
        animation: _controller,
        builder: (context, child) {
          final autoSwing = math.sin(_controller.value * 2 * math.pi) * 0.10;
          final rotY = autoSwing + (_pointer.dx * 0.35);
          final rotX = _pointer.dy * -0.22;
          final floatY = math.sin(_controller.value * 2 * math.pi) * 8;

          return Transform.translate(
            offset: Offset(0, floatY),
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
          );
        },
        child: _LogoImage(size: widget.size),
      ),
    );
  }
}

class _LogoImage extends StatelessWidget {
  final double size;
  const _LogoImage({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.wheatGold.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 18)),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.espressoDeep,
            alignment: Alignment.center,
            child: const Icon(Icons.eco, color: AppColors.wheatGold, size: 60),
          ),
        ),
      ),
    );
  }
}
