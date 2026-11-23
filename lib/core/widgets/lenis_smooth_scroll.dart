import 'dart:ui';
import 'package:flutter/material.dart';

/// Lenis-inspired Smooth Scroll Behavior for Flutter (lenis.dev).
/// 
/// Mengadopsi prinsip smooth scroll Lenis untuk memberikan pergerakan gulir
/// yang berbobot, halus (buttery-smooth), dan bebas hentakan kasar:
/// 1. Mengaktifkan drag-to-scroll untuk semua pointer (Mouse, Touch, Trackpad, Stylus).
/// 2. Menggunakan fisika inersia BouncingScrollPhysics yang responsif dan luwes.
class LenisSmoothScrollBehavior extends MaterialScrollBehavior {
  const LenisSmoothScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
