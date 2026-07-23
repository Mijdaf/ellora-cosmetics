import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../models/home_banner.dart';
import '../theme/app_theme.dart';

/// Flutter's default web scroll behaviour only lets touch/stylus pointers
/// drag a scrollable — this lets touch, mouse, and trackpad all swipe the
/// banner, so it works the same way on phone and desktop browsers alike.
class _DraggableScrollBehavior extends MaterialScrollBehavior {
  const _DraggableScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// The promotional banner strip near the top of the Home page — full-width,
/// edge-to-edge photos (seasonal offers, new drops, announcements) that
/// auto-advance every 5 seconds and loop back to the start. Just a swipe
/// and a row of dots below — no left/right arrow buttons on the sides, so
/// nothing but the photo and the dots ever shows on top of it.
class HomeBannerSlideshow extends StatefulWidget {
  final List<HomeBanner> banners;
  final double height;
  // When false, the dot indicators are not drawn on top of the slides —
  // used when the caller wants to render its own dot row elsewhere (e.g.
  // underneath the slideshow) instead of overlaid on the photo.
  final bool showDots;
  // Notified on every page change so a caller that hid the built-in dots
  // (showDots: false) can drive its own external dot row from this.
  final ValueChanged<int>? onPageChanged;

  const HomeBannerSlideshow({
    super.key,
    required this.banners,
    this.height = 220,
    this.showDots = true,
    this.onPageChanged,
  });

  @override
  State<HomeBannerSlideshow> createState() => _HomeBannerSlideshowState();
}

class _HomeBannerSlideshowState extends State<HomeBannerSlideshow> {
  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoplay();
  }

  void _startAutoplay() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _autoAdvance());
  }

  @override
  void didUpdateWidget(covariant HomeBannerSlideshow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _page = 0;
      _startAutoplay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _autoAdvance() {
    if (!_controller.hasClients) return;
    final next = _page + 1 >= widget.banners.length ? 0 : _page + 1;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: const _DraggableScrollBehavior(),
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.banners.length,
                // A manual swipe re-targets the very next timer tick
                // smoothly instead of fighting it.
                onPageChanged: (i) {
                  setState(() => _page = i);
                  widget.onPageChanged?.call(i);
                },
                itemBuilder: (context, i) {
                  final banner = widget.banners[i];
                  return Image.network(
                    banner.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceCream,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_outlined, color: AppColors.espressoDeep.withOpacity(0.35), size: 40),
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showDots && widget.banners.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.banners.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
